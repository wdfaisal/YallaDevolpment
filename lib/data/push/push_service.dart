import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/env.dart';
import '../api/token_store.dart';
import '../repositories/account_repository.dart';

/// Result of trying to enable OS push.
///
/// [unconfigured] is a normal state for builds without Firebase credentials and
/// is not an error: the in-app notification center keeps working.
enum PushStatus { unconfigured, initializing, denied, ready, failed }

/// A push message reduced to the fields the app actually uses.
class PushMessage {
  const PushMessage({required this.title, required this.body, this.orderId});

  final String title;
  final String body;
  final String? orderId;
}

/// Thin wrapper around Firebase Messaging.
///
/// Every method is safe to call when Firebase is not configured: the service
/// returns an honest "unavailable" result instead of inventing delivery. It
/// never throws to the UI.
class PushService {
  PushService({
    required AccountRepository accountRepository,
    required TokenStore tokenStore,
  })  : _accountRepository = accountRepository,
        _tokenStore = tokenStore;

  final AccountRepository _accountRepository;
  final TokenStore _tokenStore;

  FirebaseMessaging? _messaging;
  bool _initialised = false;
  PushStatus _status = Env.firebasePushConfigured
      ? PushStatus.initializing
      : PushStatus.unconfigured;

  PushStatus get status => _status;

  bool get isConfigured => Env.firebasePushConfigured;

  /// Initialises Firebase once. Returns [PushStatus.unconfigured] without
  /// touching Firebase when the build has no credentials.
  Future<PushStatus> initialize() async {
    // A failed attempt may be retried (for example after a temporary network
    // error), so it must not latch the service into a permanent failure. When
    // Firebase is already up, there is nothing to redo.
    if (_initialised && (_messaging != null || _status != PushStatus.failed)) {
      return _status;
    }
    _initialised = true;

    if (!Env.firebasePushConfigured) {
      _status = PushStatus.unconfigured;
      return _status;
    }

    final options = Env.firebaseOptions;
    if (options == null) {
      _status = PushStatus.unconfigured;
      return _status;
    }

    try {
      try {
        await Firebase.initializeApp(options: options);
      } on FirebaseException catch (error) {
        // A hot restart can initialise the default app twice; that is safe.
        if (error.code != 'duplicate-app') rethrow;
      }
      _messaging = FirebaseMessaging.instance;
      // Firebase is ready, but push is only "ready" once a token is registered
      // for the signed-in customer. Guests stay here without a misleading note.
      _status = PushStatus.initializing;
    } catch (_) {
      _messaging = null;
      _status = PushStatus.failed;
    }
    return _status;
  }

  Stream<PushMessage> get foregroundMessages {
    if (_messaging == null) return const Stream<PushMessage>.empty();
    return FirebaseMessaging.onMessage.map(_toMessage);
  }

  Stream<PushMessage> get openedMessages {
    if (_messaging == null) return const Stream<PushMessage>.empty();
    return FirebaseMessaging.onMessageOpenedApp.map(_toMessage);
  }

  Stream<String> get tokenRefreshes {
    final messaging = _messaging;
    if (messaging == null) return const Stream<String>.empty();
    // The FCM token is still the value the backend sends to; the newer
    // `onRegistered` stream exposes the installation id instead.
    // ignore: deprecated_member_use
    return messaging.onTokenRefresh;
  }

  /// Message that launched the app from a terminated state, if any.
  Future<PushMessage?> initialMessage() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      final message = await messaging.getInitialMessage();
      return message == null ? null : _toMessage(message);
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _status = PushStatus.denied;
        return false;
      }
      return true;
    } catch (_) {
      _status = PushStatus.failed;
      return false;
    }
  }

  Future<String?> currentToken() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      // The backend sends to the classic FCM registration token.
      // ignore: deprecated_member_use
      return await messaging.getToken(
        vapidKey: kIsWeb && Env.firebaseVapidKey.isNotEmpty
            ? Env.firebaseVapidKey
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Asks for the OS notification permission as soon as the app opens.
  ///
  /// Guests are asked too: the permission and the FCM token belong to the
  /// device, not to an account. The token is cached locally and registered with
  /// the backend when the customer signs in, so the OS prompt appears on first
  /// open instead of waiting for the first sign-in or order.
  ///
  /// Returns the resulting status. A guest with a token stays `initializing`
  /// because no backend row exists yet; it becomes `ready` only after
  /// [registerCurrentToken] succeeds.
  Future<PushStatus> prepareForPush() async {
    await initialize();
    if (_messaging == null) return _status;

    if (!await requestPermission()) return _status;

    final token = await currentToken();
    if (token == null || token.isEmpty) {
      if (_status != PushStatus.failed) _status = PushStatus.initializing;
      return _status;
    }

    await _tokenStore.writeDeviceToken(token);
    if (_status != PushStatus.ready) _status = PushStatus.initializing;
    return _status;
  }

  /// Asks for permission, obtains the FCM token and stores it on the backend.
  ///
  /// Sets [status] so callers can show the honest reason: `denied` when the OS
  /// permission is off, `failed` when the token or the backend call fails.
  Future<bool> registerCurrentToken() async {
    await initialize();
    if (_messaging == null) return false;
    if (!await requestPermission()) {
      if (_status != PushStatus.failed) _status = PushStatus.denied;
      return false;
    }

    final token = await currentToken();
    if (token == null || token.isEmpty) {
      _status = PushStatus.failed;
      return false;
    }

    // Keep the token locally before the network call so sign-out can still
    // remove it if the backend was unreachable right now.
    await _tokenStore.writeDeviceToken(token);

    try {
      await _accountRepository.registerDevice(
        token: token,
        platform: _platform,
        appVersion: Env.appVersion,
      );
      _status = PushStatus.ready;
      return true;
    } catch (_) {
      _status = PushStatus.failed;
      return false;
    }
  }

  /// Removes the last registered token from the backend. Called on sign-out so
  /// the next account on the same device does not receive the old account's
  /// notifications.
  Future<void> unregisterStoredToken() async {
    final token = await _tokenStore.readDeviceToken();
    if (token == null || token.isEmpty) return;
    try {
      await _accountRepository.unregisterDevice(token);
    } catch (_) {
      // The backend may already have dropped the token; local cleanup still
      // runs so a later account never inherits it.
    }
    await _tokenStore.clearDeviceToken();
  }

  String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'other';
    }
  }

  PushMessage _toMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final dataTitle = data['title'];
    final dataBody = data['body'];
    final dataOrderId = data['orderId'];
    return PushMessage(
      title: notification?.title ?? (dataTitle is String ? dataTitle : ''),
      body: notification?.body ?? (dataBody is String ? dataBody : ''),
      orderId: dataOrderId is String ? dataOrderId : null,
    );
  }
}
