import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Compile-time configuration. The app is live-only: every value shown to the
/// customer comes from the real backend. There is no preview/mock mode.
class Env {
  const Env._();

  /// Explicit override: `--dart-define=API_BASE_URL=http://192.168.1.10:4000`.
  /// Empty when the build did not provide one.
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  /// Port the API listens on. Override with `--dart-define=API_PORT=4000`.
  static const int apiPort =
      int.fromEnvironment('API_PORT', defaultValue: 4000);

  /// LAN address of the machine that runs the backend, used by native builds so
  /// a real phone on the same Wi-Fi reaches it without extra flags.
  /// Override with `--dart-define=LAN_HOST=192.168.1.10`.
  static const String _lanHost = String.fromEnvironment(
    'LAN_HOST',
    defaultValue: '10.160.175.182',
  );

  /// Base URL of the backend.
  ///
  /// Precedence:
  /// 1. an explicit `API_BASE_URL` dart-define (always wins);
  /// 2. on the web, the host that served the app, so opening the app from a
  ///    phone on the LAN (`http://192.168.x.x:8080`) reaches the backend on the
  ///    same machine without rebuilding (`http://192.168.x.x:4000`);
  /// 3. `http://<LAN_HOST>:4000` for native builds on a phone in the same
  ///    network, which also works from this machine.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) return 'http://$host:$apiPort';
    }
    return 'http://$_lanHost:$apiPort';
  }

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // ---------------------------------------------------------------------------
  // Firebase / push. Every value is optional: a build without credentials still
  // works and the notification center keeps using the live backend API. Pass
  // values with `--dart-define=FIREBASE_API_KEY=...` etc.
  // ---------------------------------------------------------------------------
  static const String _firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');
  static const String _firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String _firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _firebaseMeasurementId =
      String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  /// A single app id can be shared, but Android/iOS/Web usually have their own.
  /// The platform-specific define wins when present.
  static const String _firebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID');
  static const String _firebaseAppIdAndroid =
      String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
  static const String _firebaseAppIdIos =
      String.fromEnvironment('FIREBASE_APP_ID_IOS');
  static const String _firebaseAppIdWeb =
      String.fromEnvironment('FIREBASE_APP_ID_WEB');

  /// Web Push certificate (VAPID) key. Only needed for push on the web.
  static const String firebaseVapidKey =
      String.fromEnvironment('FIREBASE_VAPID_KEY');

  static String get _platformAppId {
    if (kIsWeb) {
      return _firebaseAppIdWeb.isNotEmpty ? _firebaseAppIdWeb : _firebaseAppId;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _firebaseAppIdAndroid.isNotEmpty
          ? _firebaseAppIdAndroid
          : _firebaseAppId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _firebaseAppIdIos.isNotEmpty ? _firebaseAppIdIos : _firebaseAppId;
    }
    return _firebaseAppId;
  }

  /// True when the minimum Firebase app credentials are present. When false the
  /// app never calls Firebase and reports push as unavailable instead.
  static bool get firebaseConfigured =>
      _firebaseApiKey.isNotEmpty &&
      _platformAppId.isNotEmpty &&
      _firebaseMessagingSenderId.isNotEmpty &&
      _firebaseProjectId.isNotEmpty;

  /// Push on the web additionally needs a VAPID key and a registered service
  /// worker; without them the in-app notification center keeps working.
  static bool get firebasePushConfigured =>
      firebaseConfigured && (!kIsWeb || firebaseVapidKey.isNotEmpty);

  /// Options for the current platform, or null when Firebase is unconfigured.
  static FirebaseOptions? get firebaseOptions {
    if (!firebaseConfigured) return null;
    return FirebaseOptions(
      apiKey: _firebaseApiKey,
      appId: _platformAppId,
      messagingSenderId: _firebaseMessagingSenderId,
      projectId: _firebaseProjectId,
      authDomain: _firebaseAuthDomain.isEmpty ? null : _firebaseAuthDomain,
      storageBucket:
          _firebaseStorageBucket.isEmpty ? null : _firebaseStorageBucket,
      measurementId:
          _firebaseMeasurementId.isEmpty ? null : _firebaseMeasurementId,
    );
  }
}
