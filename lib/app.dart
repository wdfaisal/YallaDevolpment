import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/app_system_ui.dart';
import 'core/design/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'navigation/app_router.dart';
import 'presentation/push/push_lifecycle.dart';
import 'state/language_controller.dart';

/// Shared messenger so background/foreground push alerts can be shown from the
/// lifecycle coordinator, which sits above the navigator.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class YallaApp extends ConsumerWidget {
  const YallaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Yalla Talabat',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(isArabic: language == 'ar'),
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      locale: Locale(language),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        // GlobalWidgetsLocalizations resolves Arabic to RTL; the framework
        // DefaultWidgetsLocalizations is always LTR.
        GlobalWidgetsLocalizations.delegate,
        AppMaterialLocalizationsDelegate(),
        AppCupertinoLocalizationsDelegate(),
      ],
      builder: (context, child) => PushLifecycle(
        messengerKey: appScaffoldMessengerKey,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUi.light,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routerConfig: router,
    );
  }
}
