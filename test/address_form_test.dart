import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/presentation/addresses/address_form_screen.dart';
import 'package:yalla_talabat_customer/presentation/addresses/widgets/address_location_card.dart';
import 'package:yalla_talabat_customer/presentation/addresses/widgets/address_save_bar.dart';
import 'package:yalla_talabat_customer/presentation/addresses/widgets/address_type_selector.dart';

import 'support/test_app.dart';

Future<void> _pumpForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(testApp(const AddressFormScreen()));
  await tester.pumpAndSettle();
}

/// The form must stay flat: no surface in the tree may paint a shadow.
void _expectNoShadows(WidgetTester tester) {
  for (final element in find.byType(Container).evaluate()) {
    final widget = element.widget as Container;
    final decoration = widget.decoration;
    if (decoration is BoxDecoration) {
      expect(
        decoration.boxShadow,
        isNull,
        reason: 'address form surfaces must stay shadow-free',
      );
    }
  }
}

void main() {
  testWidgets('renders the flat Stitch sections and the outlined CTA', (
    tester,
  ) async {
    await _pumpForm(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('إضافة عنوان جديد'), findsOneWidget);
    expect(find.byType(AddressLocationCard), findsOneWidget);
    expect(find.byType(AddressTypeSelector), findsOneWidget);
    expect(find.text('نوع العنوان'), findsOneWidget);
    expect(find.text('منزل'), findsWidgets);
    expect(find.text('عمل / مكتب'), findsOneWidget);
    expect(find.text('استراحة'), findsOneWidget);
    expect(find.text('أخرى'), findsOneWidget);
    expect(find.text('بيانات الموقع الدقيقة'), findsOneWidget);
    expect(find.text('المدينة والحي'), findsOneWidget);
    expect(find.text('اسم الشارع الرئيسي والفرعي'), findsOneWidget);
    expect(find.text('رقم المبنى / الفيلا'), findsOneWidget);
    expect(find.text('الدور / الشقة'), findsOneWidget);
    expect(find.text('معلم بارز قريب لتسهيل الوصول'), findsOneWidget);
    expect(find.text('مرافق التوصيل وملاحظات الكابتن'), findsOneWidget);
    expect(find.byType(AddressSaveBar), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);

    // The preference card sits below the fold; scroll it into the tree.
    await tester.scrollUntilVisible(
      find.text('تعيين كعنوان افتراضي للطلبات'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('تعيين كعنوان افتراضي للطلبات'), findsOneWidget);
    _expectNoShadows(tester);
  });

  testWidgets('the "other" type reveals a custom label field', (tester) async {
    await _pumpForm(tester);

    expect(find.text('اسم العنوان'), findsNothing);
    await tester.tap(find.text('أخرى'));
    await tester.pumpAndSettle();

    expect(find.text('اسم العنوان'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'بيت العائلة');
    await tester.pumpAndSettle();
    expect(find.text('بيت العائلة'), findsOneWidget);
  });

  testWidgets('facility chips toggle the soft green state', (tester) async {
    await _pumpForm(tester);

    final elevator = find.text('مصعد متوفر');
    expect(elevator, findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.ensureVisible(elevator);
    await tester.pumpAndSettle();
    await tester.tap(elevator);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(elevator);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('the coordinates sheet stores a pin on the card', (tester) async {
    await _pumpForm(tester);

    expect(find.text('لا يوجد موقع محدد'), findsOneWidget);
    final enter = find.text('إدخال الإحداثيات');
    await tester.ensureVisible(enter);
    await tester.pumpAndSettle();
    await tester.tap(enter);
    await tester.pumpAndSettle();

    expect(find.text('إحداثيات الموقع'), findsOneWidget);
    final fields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '24.7136');
    await tester.enterText(fields.at(1), '46.6753');
    await tester.tap(find.text('حفظ الموقع'));
    await tester.pumpAndSettle();

    expect(find.text('محدد'), findsOneWidget);
    expect(find.text('لا يوجد موقع محدد'), findsNothing);
  });

  testWidgets('saving without a street shows the inline error', (
    tester,
  ) async {
    await _pumpForm(tester);

    await tester.tap(find.text('حفظ العنوان'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل اسم الشارع أو الحي'), findsOneWidget);
  });
}
