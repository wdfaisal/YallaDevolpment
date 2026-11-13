import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Material localizations are only used for framework strings (tooltips,
/// dialogs). The customer-facing copy comes from [L10n]. The default delegate
/// only supports English, so this delegate keeps every locale supported while
/// still letting [Localizations.localeOf] report the real language.
class AppMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const AppMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(const DefaultMaterialLocalizations());

  @override
  bool shouldReload(AppMaterialLocalizationsDelegate old) => false;
}

/// Cupertino framework strings (used by a few Material widgets) for every
/// locale. The app ships its own copy, so the framework defaults are enough.
class AppCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const AppCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(AppCupertinoLocalizationsDelegate old) => false;
}
