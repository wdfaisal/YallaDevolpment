import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the customer session token. Native builds use the platform secure
/// store; on web the plugin uses WebCrypto-backed storage. If the platform
/// store is unavailable the token is kept in memory only for the session, and
/// the app still works (the httpOnly cookie remains the web fallback).
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'yalla_customer_session_token';

  final FlutterSecureStorage _storage;
  String? _memory;
  String _language = 'ar';

  /// Last persisted UI language (`ar`/`en`), available synchronously after
  /// [loadPreferences] runs at startup.
  String get cachedLanguage => _language;

  Future<void> loadPreferences() async {
    final stored = await readLanguage();
    if (stored != null && (stored == 'ar' || stored == 'en')) _language = stored;
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
}
