import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/core/widgets/app_image.dart';
import 'package:yalla_talabat_customer/data/models/cart.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/presentation/restaurant/widgets/restaurant_cart_tray.dart';
import 'package:yalla_talabat_customer/presentation/restaurant/widgets/restaurant_menu_item_card.dart';
import 'package:yalla_talabat_customer/presentation/restaurant/widgets/restaurant_meta_card.dart';

import 'support/test_app.dart';

CatalogRestaurant _restaurant({
  int etaMinutes = 20,
  double rating = 4.5,
  int ratingCount = 120,
  String? logoUrl,
}) {
  return CatalogRestaurant(
    id: 'res_1',
    name: 'مطعم الاختبار',
    cuisine: 'برجر • بطاطس',
    rating: rating,
    ratingCount: ratingCount,
    logoUrl: logoUrl,
    bannerUrl: null,
    accepting: true,
    openNow: true,
    statusLabel: 'open',
    prepMinutes: 15,
    distanceKm: 2.4,
    deliveryFeeMinor: 0,
    minOrderMinor: 2500,
    etaMinutes: etaMinutes,
    offerCount: 0,
    categories: const [],
  );
}

CatalogMenuItem _item({
  int priceMinor = 12000,
  bool available = true,
  int? calories,
}) {
  return CatalogMenuItem(
    id: 'item_1',
    restaurantId: 'res_1',
    restaurantName: 'مطعم الاختبار',
    categoryId: 'cat_1',
    categoryName: 'الأكثر طلباً',
    name: 'برجر كلاسيك',
    description: 'لحم مشوي مع جبنة شيدر.',
    priceMinor: priceMinor,
    offerPriceMinor: null,
    offerTitleAr: null,
    offerTitleEn: null,
    offerDiscountPercent: null,
    available: available,
    prepMinutes: 12,
    imageUrls: const [],
    calories: calories,
    badgeAr: null,
    badgeEn: null,
    optionGroups: const [],
  );
}

CatalogRestaurantDetail _detail({
  int etaMinutes = 20,
  int? deliveryFeeMinor = 0,
  List<CatalogOffer> offers = const [],
  String? logoUrl,
}) {
  return CatalogRestaurantDetail(
    restaurant: _restaurant(etaMinutes: etaMinutes, logoUrl: logoUrl),
    address: 'الرياض',
    phone: '0500000000',
    opensAt: '09:00',
    closesAt: '23:00',
    deliveryFeeMinor: deliveryFeeMinor,
    minOrderMinor: 2500,
    menu: const [],
    offers: offers,
    isFavorite: false,
  );
}

CatalogOffer _offer() {
  return const CatalogOffer(
    id: 'off_1',
    restaurantId: 'res_1',
    restaurantName: 'مطعم الاختبار',
    titleAr: 'خصم 10%',
    titleEn: '10% off',
    descriptionAr: 'على كل القائمة',
    descriptionEn: 'On the whole menu',
    imageUrl: null,
    discountType: 'percentage',
    discountValue: 10,
    endsAt: '2026-12-31',
    items: [],
  );
}

CartLine _line({int quantity = 1, int lineTotalMinor = 12000}) {
  return CartLine(
    id: 'line_1',
    menuItemId: 'item_1',
    name: 'برجر كلاسيك',
    imageUrl: null,
    quantity: quantity,
    notes: '',
    options: const [],
    unitBaseMinor: 12000,
    unitOptionsMinor: 0,
    unitOriginalMinor: 12000,
    unitTotalMinor: 12000,
    offerDiscountMinor: 0,
    offerTitleAr: null,
    offerTitleEn: null,
    lineTotalMinor: lineTotalMinor,
    available: true,
    unavailableReason: null,
  );
}

CartResponse _cart({
  String? restaurantId = 'res_1',
  List<CartLine> lines = const [],
  int itemCount = 0,
}) {
  return CartResponse(
    cartId: lines.isEmpty ? null : 'cart_1',
    restaurantId: restaurantId,
    restaurantName: restaurantId == null ? null : 'مطعم الاختبار',
    lines: lines,
    itemCount: itemCount,
    updatedAt: null,
    quote: null,
  );
}

void main() {
  group('RestaurantMetaCard', () {
    testWidgets('shows the real name, cuisine and four metrics', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: RestaurantMetaCard(
                detail: _detail(),
                l10n: const L10n(true),
              ),
            ),
          ),
        ),
      );

      expect(find.text('مطعم الاختبار'), findsOneWidget);
      expect(find.text('برجر • بطاطس'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('+120 تقييم'), findsOneWidget);
      expect(find.text('رسوم التوصيل'), findsOneWidget);
      expect(find.text('الحد الأدنى'), findsOneWidget);
    });

    testWidgets('only renders pills backed by restaurant data', (tester) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: RestaurantMetaCard(
                detail: _detail(offers: [_offer()]),
                l10n: const L10n(true),
              ),
            ),
          ),
        ),
      );

      // ETA 20 => fast delivery, fee 0 => free delivery, one offer.
      expect(find.text('توصيل سريع جداً'), findsOneWidget);
      expect(find.text('توصيل مجاني'), findsOneWidget);
      expect(find.text('خصومات حصرية يلا'), findsOneWidget);

      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: RestaurantMetaCard(
                detail: _detail(etaMinutes: 45, deliveryFeeMinor: 1500),
                l10n: const L10n(true),
              ),
            ),
          ),
        ),
      );

      expect(find.text('توصيل سريع جداً'), findsNothing);
      expect(find.text('توصيل مجاني'), findsNothing);
      expect(find.text('خصومات حصرية يلا'), findsNothing);
    });

    testWidgets('shows the restaurant logo instead of a generic icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: RestaurantMetaCard(
                detail: _detail(logoUrl: '/api/media/images/logo.png'),
                l10n: const L10n(true),
              ),
            ),
          ),
        ),
      );

      final logo = tester.widget<AppImage>(find.byType(AppImage));
      expect(logo.url, '/api/media/images/logo.png');
      expect(logo.width, 48);
      expect(logo.height, 48);
    });
  });

  group('RestaurantMenuItemCard', () {
    testWidgets('shows the price, quantity and wires the stepper', (
      tester,
    ) async {
      var increments = 0;
      var decrements = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: RestaurantMenuItemCard(
              item: _item(),
              l10n: const L10n(true),
              quantity: 2,
              onTap: () {},
              onIncrement: () => increments++,
              onDecrement: () => decrements++,
            ),
          ),
        ),
      );

      expect(find.text('برجر كلاسيك'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byTooltip('زيادة'));
      await tester.tap(find.byTooltip('تقليل'));
      expect(increments, 1);
      expect(decrements, 1);
    });

    testWidgets('disables adding when the item is unavailable', (
      tester,
    ) async {
      var increments = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: RestaurantMenuItemCard(
              item: _item(available: false),
              l10n: const L10n(true),
              quantity: 0,
              onTap: () {},
              onIncrement: () => increments++,
              onDecrement: () {},
            ),
          ),
        ),
      );

      expect(find.text('نفد'), findsOneWidget);
      await tester.tap(find.byTooltip('زيادة'));
      expect(increments, 0);
    });

    testWidgets('renders the calories chip only when the API sends it', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: RestaurantMenuItemCard(
              item: _item(calories: 480),
              l10n: const L10n(true),
              quantity: 0,
              onTap: () {},
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        ),
      );

      expect(find.text('480 سعرة'), findsOneWidget);
    });
  });

  group('RestaurantCartTray', () {
    testWidgets('empty cart shows a disabled checkout', (tester) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            bottomNavigationBar: RestaurantCartTray(
              cart: _cart(),
              restaurantId: 'res_1',
              l10n: const L10n(true),
              onCheckout: () {},
            ),
          ),
        ),
      );

      expect(find.text('السلة فارغة'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('ignores a cart that belongs to another restaurant', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            bottomNavigationBar: RestaurantCartTray(
              cart: _cart(
                restaurantId: 'res_other',
                lines: [_line()],
                itemCount: 1,
              ),
              restaurantId: 'res_1',
              l10n: const L10n(true),
              onCheckout: () {},
            ),
          ),
        ),
      );

      expect(find.text('السلة فارغة'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('own cart shows the total and enables checkout', (
      tester,
    ) async {
      var checkouts = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            bottomNavigationBar: RestaurantCartTray(
              cart: _cart(
                lines: [_line(quantity: 2, lineTotalMinor: 24000)],
                itemCount: 2,
              ),
              restaurantId: 'res_1',
              l10n: const L10n(true),
              onCheckout: () => checkouts++,
            ),
          ),
        ),
      );

      expect(find.text('صنفان في السلة'), findsOneWidget);
      expect(find.text('240'), findsOneWidget);
      expect(find.text('(شامل الضريبة)'), findsOneWidget);

      await tester.tap(find.text('إتمام الطلب'));
      expect(checkouts, 1);
    });
  });

  testWidgets('meta card and tray fit a 390px phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                RestaurantMetaCard(
                  detail: _detail(offers: [_offer()]),
                  l10n: const L10n(true),
                ),
                RestaurantMenuItemCard(
                  item: _item(calories: 480),
                  l10n: const L10n(true),
                  quantity: 1,
                  onTap: () {},
                  onIncrement: () {},
                  onDecrement: () {},
                ),
              ],
            ),
          ),
          bottomNavigationBar: RestaurantCartTray(
            cart: _cart(
              lines: [_line(quantity: 2, lineTotalMinor: 24000)],
              itemCount: 2,
            ),
            restaurantId: 'res_1',
            l10n: const L10n(true),
            onCheckout: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
