import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/design/app_system_ui.dart';
import 'data/api/token_store.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the system bars so each page's own background (a restaurant
  // cover, the tracking map, a white header) reaches the notch instead of a
  // black system bar. The app is light-only, so the icons are dark by default.
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(AppSystemUi.light);
  }

  // The language preference is needed synchronously by the first frame.
  final tokenStore = TokenStore();
  await tokenStore.loadPreferences();

  final container = ProviderContainer(
    overrides: [tokenStoreProvider.overrideWithValue(tokenStore)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const YallaApp(),
    ),
  );
}
