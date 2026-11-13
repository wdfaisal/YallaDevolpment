import 'package:flutter/foundation.dart' show kIsWeb;

/// Compile-time configuration. The app is live-only: every value shown to the
/// customer comes from the real backend. There is no preview/mock mode.
class Env {
  const Env._();

  /// Explicit override: `--dart-define=API_BASE_URL=http://192.168.1.10:4000`.
  /// Empty when the build did not provide one.
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Port the API listens on. Override with `--dart-define=API_PORT=4000`.
  static const int apiPort = int.fromEnvironment('API_PORT', defaultValue: 4000);

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
}
