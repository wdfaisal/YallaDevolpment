import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/core/widgets/app_image.dart';
import 'package:yalla_talabat_customer/data/models/account.dart';
import 'package:yalla_talabat_customer/data/models/cart.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/presentation/cart/widgets/checkout_address_card.dart';
import 'package:yalla_talabat_customer/presentation/cart/widgets/checkout_bottom_tray.dart';
import 'package:yalla_talabat_customer/presentation/cart/widgets/checkout_free_delivery_banner.dart';
import 'package:yalla_talabat_customer/presentation/cart/widgets/checkout_item_card.dart';
import 'package:yalla_talabat_customer/presentation/cart/widgets/checkout_payment_card.dart';
import 'package:yalla_talabat_customer/presentation/cart/widgets/checkout_restaurant_card.dart';
import 'package:yalla_talabat_customer/presentation/cart/widgets/checkout_summary_card.dart';

import 'support/test_app.dart';

const _l10n = L10n(true);

CatalogRestaurant _restaurant() {
  return const CatalogRestaurant(
    id: 'res_1',
    name: 'برجر بوتيك',
    cuisine: 'برجر',
    rating: 4.8,
    ratingCount: 1200,
    logoUrl: '/api/media/images/logo.png',
    bannerUrl: null,
    accepting: true,
    openNow: true,
    statusLabel: 'open',
    prepMinutes: 20,
    distanceKm: 2.4,
    deliveryFeeMinor: 600,
    minOrderMinor: 0,
    etaMinutes: 25,
    offerCount: 0,
    categories: [],
  );
}

CatalogRestaurantDetail _detail() {
  return CatalogRestaurantDetail(
    restaurant: _restaurant(),
    address: 'الرياض',
    phone: '0500000000',
    opensAt: '09:00',
    closesAt: '23:00',
    deliveryFeeMinor: 600,
    minOrderMinor: 0,
    menu: const [],
    offers: const [],
    isFavorite: false,
  );
}

CartLine _line({
  int quantity = 1,
  int lineTotalMinor = 4600,
  bool available = true,
  String notes = '',
  List<CartLineOption> options = const [],
}) {
  return CartLine(
    id: 'line_1',
    menuItemId: 'item_1',
    name: 'كلاسيك سموك برجر',
    imageUrl: '/api/media/images/burger.jpg',
    quantity: quantity,
    notes: notes,
    options: options,
    unitBaseMinor: 4600,
    unitOptionsMinor: 0,
    unitTotalMinor: 4600,
    lineTotalMinor: lineTotalMinor,
    available: available,
    unavailableReason: null,
  );
}

CartResponse _cart({List<CartLine>? lines}) {
  final resolved = lines ?? [_line()];
  return CartResponse(
    cartId: 'cart_1',
    restaurantId: 'res_1',
    restaurantName: 'برجر بوتيك',
    lines: resolved,
    itemCount: resolved.fold<int>(0, (sum, line) => sum + line.quantity),
    updatedAt: null,
    quote: null,
  );
}

PaymentMethodOption _method(
  String method,
  String label, {
  bool usable = true,
  bool requiresReference = false,
}) {
  return PaymentMethodOption(
    method: method,
    enabled: usable,
    available: usable,
    reason: usable ? null : 'غير متاح حالياً',
    labelAr: label,
    labelEn: label,
    requiresReference: requiresReference,
  );
}

CartQuote _quote({
  int subtotalMinor = 7000,
  int deliveryFeeMinor = 600,
  int deliveryFeeOriginalMinor = 1500,
  int discountMinor = 2100,
  AppliedCoupon? coupon = const AppliedCoupon(
    code: 'YALLA30',
    discountMinor: 2100,
    description: '',
  ),
  List<PaymentMethodOption>? paymentMethods,
  bool freeDeliveryApplied = true,
}) {
  return CartQuote(
    currency: 'SAR',
    restaurantId: 'res_1',
    restaurantName: 'برجر بوتيك',
    branchId: 'branch_1',
    lines: [_line()],
    itemCount: 1,
    subtotalMinor: subtotalMinor,
    deliveryFeeMinor: deliveryFeeMinor,
    deliveryFeeOriginalMinor: deliveryFeeOriginalMinor,
    discountMinor: discountMinor,
    vatMinor: 825,
    totalMinor: 6325,
    minOrderMinor: 0,
    meetsMinimum: true,
    freeDeliveryApplied: freeDeliveryApplied,
    coupon: coupon,
    couponError: null,
    taxMode: 'inclusive',
    taxRateBasisPoints: 1500,
    fulfillment: 'delivery',
    scheduledFor: null,
    paymentMethods: paymentMethods ??
        [
          _method('wallet', 'المحفظة'),
          _method('cash_on_delivery', 'الدفع عند الاستلام'),
        ],
    warnings: const [],
  );
}

CustomerAddressRecord _address() {
  return const CustomerAddressRecord(
    id: 'addr_1',
    label: 'المنزل',
    address: 'حي النرجس، شارع أنس بن مالك، فيلا 14',
    lat: null,
    lng: null,
    isDefault: true,
    instructions: '',
    zoneId: null,
    cityId: null,
    updatedAt: null,
  );
}

void main() {
  group('CheckoutRestaurantCard', () {
    testWidgets('shows the live restaurant, ETA, rating and menu action', (
      tester,
    ) async {
      var menus = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutRestaurantCard(
                cart: _cart(),
                detail: _detail(),
                l10n: _l10n,
                onMenuTap: () => menus++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('طلبك من'), findsOneWidget);
      expect(find.text('مفتوح للطلبات'), findsOneWidget);
      expect(find.text('برجر بوتيك'), findsOneWidget);
      expect(find.text('25 دقيقة'), findsOneWidget);
      expect(find.text('4.8 (+1200 تقييم)'), findsOneWidget);

      final logo = tester.widget<AppImage>(find.byType(AppImage));
      expect(logo.url, '/api/media/images/logo.png');
      expect(logo.width, 56);
      expect(logo.height, 56);

      await tester.tap(find.byTooltip('القائمة'));
      expect(menus, 1);
    });

    testWidgets('shows a closed status when the API says so', (tester) async {
      final closed = CatalogRestaurantDetail(
        restaurant: CatalogRestaurant(
          id: _restaurant().id,
          name: _restaurant().name,
          cuisine: _restaurant().cuisine,
          rating: _restaurant().rating,
          ratingCount: _restaurant().ratingCount,
          logoUrl: _restaurant().logoUrl,
          bannerUrl: null,
          accepting: false,
          openNow: false,
          statusLabel: 'closed',
          prepMinutes: 20,
          distanceKm: 2.4,
          deliveryFeeMinor: 600,
          minOrderMinor: 0,
          etaMinutes: 25,
          offerCount: 0,
          categories: const [],
        ),
        address: 'الرياض',
        phone: '0500000000',
        opensAt: '09:00',
        closesAt: '23:00',
        deliveryFeeMinor: 600,
        minOrderMinor: 0,
        menu: const [],
        offers: const [],
        isFavorite: false,
      );
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutRestaurantCard(
                cart: _cart(),
                detail: closed,
                l10n: _l10n,
              ),
            ),
          ),
        ),
      );

      expect(find.text('مغلق'), findsOneWidget);
      expect(find.text('مفتوح للطلبات'), findsNothing);
    });
  });

  group('CheckoutItemCard', () {
    testWidgets('renders options, notes, price and wires actions', (
      tester,
    ) async {
      var removed = 0;
      int? newQuantity;
      final line = _line(
        notes: 'بدون بصل',
        options: const [
          CartLineOption(
            groupId: 'g1',
            groupNameAr: 'الحجم',
            groupNameEn: 'Size',
            optionId: 'o1',
            nameAr: 'كبير',
            nameEn: 'Large',
            priceDeltaMinor: 0,
          ),
          CartLineOption(
            groupId: 'g2',
            groupNameAr: 'إضافات',
            groupNameEn: 'Extras',
            optionId: 'o2',
            nameAr: 'جبنة إضافية',
            nameEn: 'Extra cheese',
            priceDeltaMinor: 200,
          ),
        ],
      );
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutItemCard(
                line: line,
                currency: 'SAR',
                l10n: _l10n,
                onQuantity: (value) => newQuantity = value,
                onRemove: () => removed++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('كلاسيك سموك برجر'), findsOneWidget);
      expect(find.text('كبير • جبنة إضافية'), findsOneWidget);
      expect(find.text('بدون بصل'), findsOneWidget);
      expect(find.text('46.00'), findsOneWidget);
      expect(find.text('SAR'), findsOneWidget);

      final image = tester.widget<AppImage>(find.byType(AppImage));
      expect(image.width, 80);
      expect(image.height, 80);

      await tester.tap(find.byIcon(Icons.add));
      expect(newQuantity, 2);
      await tester.tap(find.byTooltip('حذف الصنف'));
      expect(removed, 1);
    });

    testWidgets('shows the unavailable reason from the cart', (tester) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutItemCard(
                line: _line(available: false),
                currency: 'SAR',
                l10n: _l10n,
                onQuantity: (_) {},
                onRemove: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('غير متاح حالياً'), findsOneWidget);
    });
  });

  group('CheckoutFreeDeliveryBanner', () {
    testWidgets('shows the saved amount and a completed progress bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutFreeDeliveryBanner(quote: _quote(), l10n: _l10n),
            ),
          ),
        ),
      );

      expect(find.text('وفرت 9.00 SAR على رسوم التوصيل!'), findsOneWidget);
      expect(find.text('مكتمل 100%'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, 1);
    });
  });

  group('CheckoutSummaryCard', () {
    testWidgets('renders every backend quote row and the final total', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutSummaryCard(quote: _quote(), l10n: _l10n),
            ),
          ),
        ),
      );

      expect(find.text('تفاصيل الحساب'), findsOneWidget);
      expect(find.text('المجموع الفرعي'), findsOneWidget);
      expect(find.text('70.00'), findsOneWidget);
      expect(find.text('رسوم التوصيل'), findsOneWidget);
      expect(find.text('6.00'), findsOneWidget);
      expect(find.text('15.00 SAR'), findsOneWidget);
      expect(find.text('الخصم (YALLA30)'), findsOneWidget);
      expect(find.text('-21.00'), findsOneWidget);
      expect(find.text('الضريبة (15%)'), findsOneWidget);
      expect(find.text('8.25'), findsOneWidget);
      expect(find.text('الإجمالي النهائي'), findsOneWidget);
      expect(find.text('شامل الضريبة وكافة الرسوم'), findsOneWidget);
      expect(find.text('63.25'), findsOneWidget);
    });
  });

  group('CheckoutBottomTray', () {
    testWidgets('shows the total and triggers confirm when enabled', (
      tester,
    ) async {
      var confirmed = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            bottomNavigationBar: CheckoutBottomTray(
              quote: _quote(),
              l10n: _l10n,
              placing: false,
              enabled: true,
              onPressed: () => confirmed++,
            ),
          ),
        ),
      );

      expect(find.text('تأكيد ودفع الطلب'), findsOneWidget);
      expect(find.text('63.25'), findsOneWidget);

      await tester.tap(find.text('تأكيد ودفع الطلب'));
      expect(confirmed, 1);
    });

    testWidgets('disables the button while the quote is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            bottomNavigationBar: CheckoutBottomTray(
              quote: null,
              l10n: _l10n,
              placing: false,
              enabled: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('CheckoutAddressCard', () {
    testWidgets('shows the default address and opens the picker', (
      tester,
    ) async {
      var changes = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutAddressCard(
                address: _address(),
                l10n: _l10n,
                onChange: () => changes++,
                onEditInstructions: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('عنوان التوصيل'), findsOneWidget);
      expect(find.text('المنزل'), findsOneWidget);
      expect(find.text('افتراضي'), findsOneWidget);
      expect(
        find.text('حي النرجس، شارع أنس بن مالك، فيلا 14'),
        findsOneWidget,
      );
      expect(find.text('إضافة تعليمات الوصول للسائق'), findsOneWidget);

      await tester.tap(find.text('تغيير العنوان'));
      expect(changes, 1);
    });
  });

  group('CheckoutPaymentCard', () {
    testWidgets('renders the real methods and reports selection', (
      tester,
    ) async {
      String? selected;
      final wallet = const WalletSummary(
        availableMinor: 2000,
        heldMinor: 0,
        currency: 'SAR',
        entries: [],
      );
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: CheckoutPaymentCard(
                quote: _quote(
                  paymentMethods: [
                    _method('wallet', 'المحفظة'),
                    _method('cash_on_delivery', 'الدفع عند الاستلام'),
                    _method(
                      'card_gateway',
                      'بطاقة',
                      usable: false,
                      requiresReference: true,
                    ),
                  ],
                ),
                wallet: wallet,
                method: 'wallet',
                useWalletSplit: false,
                referenceController: TextEditingController(),
                l10n: _l10n,
                onSelect: (method) => selected = method,
                onSplitChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('طريقة الدفع'), findsOneWidget);
      expect(find.text('دفع إلكتروني آمن'), findsOneWidget);
      expect(find.text('المحفظة'), findsOneWidget);
      expect(find.text('الدفع عند الاستلام'), findsOneWidget);
      expect(find.text('بطاقة'), findsOneWidget);
      expect(find.text('غير متاح'), findsOneWidget);
      expect(find.text('دفع مختلط'), findsOneWidget);

      await tester.tap(find.text('الدفع عند الاستلام'));
      expect(selected, 'cash_on_delivery');
    });
  });

  testWidgets('all checkout cards fit a 390px phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final quote = _quote();
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CheckoutFreeDeliveryBanner(quote: quote, l10n: _l10n),
                  const SizedBox(height: 16),
                  CheckoutRestaurantCard(
                    cart: _cart(),
                    detail: _detail(),
                    l10n: _l10n,
                    onMenuTap: () {},
                  ),
                  const SizedBox(height: 16),
                  CheckoutItemCard(
                    line: _line(quantity: 2, lineTotalMinor: 9200),
                    currency: 'SAR',
                    l10n: _l10n,
                    onQuantity: (_) {},
                    onRemove: () {},
                  ),
                  const SizedBox(height: 16),
                  CheckoutAddressCard(
                    address: _address(),
                    l10n: _l10n,
                    onChange: () {},
                    onEditInstructions: () {},
                  ),
                  const SizedBox(height: 16),
                  CheckoutSummaryCard(quote: quote, l10n: _l10n),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CheckoutBottomTray(
            quote: quote,
            l10n: _l10n,
            placing: false,
            enabled: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('tray and summary survive a 320px phone with a large total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final quote = CartQuote(
      currency: 'SDG',
      restaurantId: 'res_1',
      restaurantName: 'برجر بوتيك',
      branchId: 'branch_1',
      lines: [_line()],
      itemCount: 1,
      subtotalMinor: 2780000,
      deliveryFeeMinor: 1200000,
      deliveryFeeOriginalMinor: 1200000,
      discountMinor: 0,
      vatMinor: 0,
      totalMinor: 3980000,
      minOrderMinor: 0,
      meetsMinimum: true,
      freeDeliveryApplied: false,
      coupon: null,
      couponError: null,
      taxMode: 'inclusive',
      taxRateBasisPoints: 0,
      fulfillment: 'delivery',
      scheduledFor: null,
      paymentMethods: [_method('cash_on_delivery', 'الدفع عند الاستلام')],
      warnings: const [],
    );

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CheckoutSummaryCard(quote: quote, l10n: _l10n),
                  const SizedBox(height: 16),
                  CheckoutItemCard(
                    line: _line(lineTotalMinor: 2780000),
                    currency: 'SDG',
                    l10n: _l10n,
                    onQuantity: (_) {},
                    onRemove: () {},
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CheckoutBottomTray(
            quote: quote,
            l10n: _l10n,
            placing: false,
            enabled: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('39,800.00'), findsNWidgets(2));
  });
}
