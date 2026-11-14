import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/data/models/cart.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/presentation/restaurant/restaurant_screen.dart';
import 'package:yalla_talabat_customer/presentation/restaurant/widgets/restaurant_cart_tray.dart';
import 'package:yalla_talabat_customer/presentation/restaurant/widgets/restaurant_top_bar.dart';
import 'package:yalla_talabat_customer/state/cart_controller.dart';
import 'package:yalla_talabat_customer/state/restaurant_detail_controller.dart';

import 'support/test_app.dart';

CatalogMenuItem _item(String id, String name) {
  return CatalogMenuItem(
    id: id,
    restaurantId: 'res_1',
    restaurantName: 'البيك',
    categoryId: 'cat_1',
    categoryName: 'أخرى',
    name: name,
    description: 'وصف',
    priceMinor: 1580000,
    offerPriceMinor: null,
    offerTitleAr: null,
    offerTitleEn: null,
    offerDiscountPercent: null,
    available: true,
    prepMinutes: 12,
    imageUrls: const [],
    calories: null,
    badgeAr: null,
    badgeEn: null,
    optionGroups: const [],
  );
}

CatalogRestaurantDetail _detail({bool withMenu = true, int itemCount = 2}) {
  return CatalogRestaurantDetail(
    restaurant: const CatalogRestaurant(
      id: 'res_1',
      name: 'البيك -Albak',
      cuisine: 'برجر',
      rating: 4.5,
      ratingCount: 120,
      logoUrl: null,
      bannerUrl: null,
      accepting: true,
      openNow: true,
      statusLabel: 'open',
      prepMinutes: 20,
      distanceKm: 2.4,
      deliveryFeeMinor: 1200,
      minOrderMinor: 0,
      etaMinutes: 40,
      offerCount: 0,
      categories: [],
    ),
    address: 'الرياض',
    phone: '0500000000',
    opensAt: '09:00',
    closesAt: '23:00',
    deliveryFeeMinor: 1200,
    minOrderMinor: 0,
    menu: withMenu
        ? [
            CatalogMenuCategory(
              id: 'cat_1',
              name: 'أخرى',
              position: 0,
              items: [
                for (var i = 0; i < itemCount; i++)
                  _item('item_$i', 'برجر دجاج $i'),
              ],
            ),
          ]
        : const [],
    offers: const [],
    isFavorite: false,
  );
}

class _FakeDetail extends RestaurantDetailController {
  _FakeDetail(this.detail);

  final CatalogRestaurantDetail detail;

  @override
  Future<CatalogRestaurantDetail> build(String id) async => detail;
}

class _FakeCart extends CartController {
  _FakeCart(this.cart);

  final CartResponse cart;

  @override
  Future<CartResponse> build() async => cart;
}

const CartResponse _emptyCart = CartResponse(
  cartId: null,
  restaurantId: null,
  restaurantName: null,
  lines: [],
  itemCount: 0,
  updatedAt: null,
  quote: null,
);

CartResponse _filledCart() {
  return const CartResponse(
    cartId: 'cart_1',
    restaurantId: 'res_1',
    restaurantName: 'البيك',
    lines: [
      CartLine(
        id: 'line_1',
        menuItemId: 'item_0',
        name: 'برجر دجاج 0',
        imageUrl: null,
        quantity: 1,
        notes: '',
        options: [],
        unitBaseMinor: 1580000,
        unitOptionsMinor: 0,
        unitOriginalMinor: 1580000,
        unitTotalMinor: 1580000,
        offerDiscountMinor: 0,
        offerTitleAr: null,
        offerTitleEn: null,
        lineTotalMinor: 1580000,
        available: true,
        unavailableReason: null,
      ),
    ],
    itemCount: 1,
    updatedAt: null,
    quote: null,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  CatalogRestaurantDetail detail, {
  CartResponse cart = _emptyCart,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    testApp(
      const RestaurantScreen(restaurantId: 'res_1'),
      overrides: [
        restaurantDetailProvider.overrideWith(() => _FakeDetail(detail)),
        cartProvider.overrideWith(() => _FakeCart(cart)),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the hero, meta card, tabs and menu items', (
    tester,
  ) async {
    await _pumpScreen(tester, _detail());

    expect(tester.takeException(), isNull);
    final backIcon = find.descendant(
      of: find.byType(RestaurantTopBar),
      matching: find.byIcon(Icons.arrow_back),
    );
    expect(backIcon, findsOneWidget);
    // Material mirrors `arrow_back` in RTL, so it renders pointing right.
    expect(Directionality.of(tester.element(backIcon)), TextDirection.rtl);
    expect(find.text('البيك -Albak'), findsOneWidget);
    // The bar title only appears once the meta title scrolls under the bar.
    expect(
      find.descendant(
        of: find.byType(RestaurantTopBar),
        matching: find.text('البيك -Albak'),
      ),
      findsNothing,
    );
    expect(find.text('أخرى'), findsWidgets);
    expect(find.text('برجر دجاج 0'), findsOneWidget);
    expect(find.text('15,800'), findsWidgets);
  });

  testWidgets('the top bar picks up the title while scrolling', (tester) async {
    await _pumpScreen(tester, _detail(itemCount: 20));

    final controller = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    controller.jumpTo(320);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(RestaurantTopBar),
        matching: find.text('البيك -Albak'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(RestaurantTopBar),
        matching: find.byIcon(Icons.arrow_back),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the cart tray stays hidden while the cart is empty', (
    tester,
  ) async {
    await _pumpScreen(tester, _detail());

    expect(find.byType(RestaurantCartTray), findsNothing);
  });

  testWidgets('the cart tray appears once an item is added', (tester) async {
    await _pumpScreen(tester, _detail(), cart: _filledCart());

    expect(find.byType(RestaurantCartTray), findsOneWidget);
    expect(find.text('إتمام الطلب'), findsOneWidget);
  });

  testWidgets('the body keeps its height above the cart tray', (tester) async {
    await _pumpScreen(tester, _detail(), cart: _filledCart());

    // Regression: the tray used an expanding Center inside
    // bottomNavigationBar, which claimed the full screen height and left the
    // body at 0px (blank restaurant page).
    final trayHeight = tester.getSize(find.byType(RestaurantCartTray)).height;
    final bodyHeight = tester.getSize(find.byType(CustomScrollView)).height;
    expect(trayHeight, lessThan(120));
    expect(bodyHeight, greaterThan(600));
  });

  testWidgets('shows the empty state when the menu has no items', (
    tester,
  ) async {
    await _pumpScreen(tester, _detail(withMenu: false));

    expect(tester.takeException(), isNull);
    expect(find.text('لا توجد بيانات لعرضها'), findsOneWidget);
    expect(find.byType(RestaurantCartTray), findsNothing);
  });
}
