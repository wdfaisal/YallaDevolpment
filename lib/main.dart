import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/api/token_store.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
