import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the customer session token. Native builds use the platform secure
/// store; on web the plugin uses WebCrypto-backed storage. If the platform
/// store is unavailable the token is kept in memory only for the session, and
/// the app still works (the httpOnly cookie remains the web fallback).
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'yalla_customer_session_token';
  static const String _notificationsKey =
      'yalla_customer_notifications_enabled';
  static const String _deviceTokenKey = 'yalla_customer_device_token';

  final FlutterSecureStorage _storage;
  String? _memory;
  String _language = 'ar';
  bool _notificationsEnabled = true;
  String? _deviceToken;

  /// Last persisted UI language (`ar`/`en`), available synchronously after
  /// [loadPreferences] runs at startup.
  String get cachedLanguage => _language;

  /// Last persisted in-app notification preference, available synchronously
  /// after [loadPreferences] runs at startup. Defaults to enabled.
  bool get cachedNotificationsEnabled => _notificationsEnabled;

  /// The last device token successfully registered with the backend, so it can
  /// be unregistered on sign-out without waiting for Firebase.
  String? get cachedDeviceToken => _deviceToken;

  Future<void> loadPreferences() async {
    final stored = await readLanguage();
    if (stored != null && (stored == 'ar' || stored == 'en')) {
      _language = stored;
    }
    final notifications = await readNotificationsEnabled();
    if (notifications != null) _notificationsEnabled = notifications;
    _deviceToken = await readDeviceToken();
  }

  Future<String?> read() async {
    if (_memory != null) return _memory;
    try {
      _memory = await _storage.read(key: _key);
    } catch (_) {
      _memory = null;
    }
    return _memory;
  }

  Future<void> write(String token) async {
    _memory = token;
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      // Memory fallback already holds the token.
    }
  }

  Future<void> clear() async {
    _memory = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing to clean up.
    }
  }

  Future<String?> readLanguage() async {
    try {
      return await _storage.read(key: 'yalla_customer_language');
    } catch (_) {
      return null;
    }
  }

  Future<void> writeLanguage(String code) async {
    _language = code;
    try {
      await _storage.write(key: 'yalla_customer_language', value: code);
    } catch (_) {
      // Language preference is non-critical.
    }
  }

  Future<bool?> readNotificationsEnabled() async {
    try {
      final stored = await _storage.read(key: _notificationsKey);
      if (stored == null) return null;
      return stored == 'true';
    } catch (_) {
      return null;
    }
  }

  Future<void> writeNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    try {
      await _storage.write(
        key: _notificationsKey,
        value: enabled ? 'true' : 'false',
      );
    } catch (_) {
      // Notification preference is non-critical.
    }
  }

  Future<String?> readDeviceToken() async {
    if (_deviceToken != null) return _deviceToken;
    try {
      _deviceToken = await _storage.read(key: _deviceTokenKey);
    } catch (_) {
      _deviceToken = null;
    }
    return _deviceToken;
  }

  Future<void> writeDeviceToken(String token) async {
    _deviceToken = token;
    try {
      await _storage.write(key: _deviceTokenKey, value: token);
    } catch (_) {
      // The token can be registered again on the next launch.
    }
  }

  Future<void> clearDeviceToken() async {
    _deviceToken = null;
    try {
      await _storage.delete(key: _deviceTokenKey);
    } catch (_) {
      // Nothing to clean up.
    }
  }
}
