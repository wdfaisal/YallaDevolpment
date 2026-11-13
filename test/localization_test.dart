import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';

void main() {
  test('Arabic and English strings are both available', () {
    const ar = L10n(true);
    const en = L10n(false);

    expect(ar.isArabic, isTrue);
    expect(en.isArabic, isFalse);
    expect(ar.appName, 'يلا طلبات');
    expect(en.appName, 'Yalla Talabat');
    expect(ar.cart, isNot(en.cart));
    expect(ar.invalidPhone, 'رقم الهاتف غير صالح');
    expect(en.invalidPhone, 'Invalid phone number');
  });

  test('newly added labels are not empty', () {
    const ar = L10n(true);
    const en = L10n(false);
    final getters = <String>[
      ar.change,
      ar.saveChanges,
      ar.profileUpdated,
      ar.ticketCreated,
      ar.replySent,
      ar.appVersion,
      ar.accountStatus,
      ar.notificationsManagedBySystem,
    ];
    expect(getters.every((value) => value.trim().isNotEmpty), isTrue);
    expect(en.change, 'Change');
    expect(en.saveChanges, 'Save changes');
  });
}
