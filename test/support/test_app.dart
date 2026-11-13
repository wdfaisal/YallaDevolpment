import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yalla_talabat_customer/core/localization/app_localizations.dart';

/// Minimal app shell for widget tests: real localizations + Riverpod scope,
/// with no router (screens only navigate from callbacks).
Widget testApp(
  Widget child, {
  Locale locale = const Locale('ar'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppMaterialLocalizationsDelegate(),
        AppCupertinoLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
      ],
      home: child,
    ),
  );
}
