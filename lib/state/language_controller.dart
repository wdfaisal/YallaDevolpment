import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// UI language. Arabic is the default; the choice persists locally.
final languageProvider = NotifierProvider<LanguageController, String>(
  LanguageController.new,
);

final isArabicProvider = Provider<bool>((ref) => ref.watch(languageProvider) == 'ar');

class LanguageController extends Notifier<String> {
  @override
  String build() => ref.watch(tokenStoreProvider).cachedLanguage;

  Future<void> setLanguage(String code) async {
    if (code != 'ar' && code != 'en') return;
    if (code == state) return;
    await ref.read(tokenStoreProvider).writeLanguage(code);
    state = code;
  }

  Future<void> toggle() => setLanguage(state == 'ar' ? 'en' : 'ar');
}
