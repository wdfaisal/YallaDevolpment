import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/design/app_colors.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/core/widgets/flat_empty_state.dart';
import 'package:yalla_talabat_customer/core/widgets/price_text.dart';
import 'package:yalla_talabat_customer/data/models/account.dart';
import 'package:yalla_talabat_customer/data/models/cart.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/presentation/favorites/favorites_screen.dart';
import 'package:yalla_talabat_customer/presentation/favorites/widgets/favorite_dish_card.dart';
import 'package:yalla_talabat_customer/presentation/favorites/widgets/favorite_restaurant_card.dart';
import 'package:yalla_talabat_customer/presentation/shared/segmented_tabs.dart';
import 'package:yalla_talabat_customer/state/cart_controller.dart';
import 'package:yalla_talabat_customer/state/favorites_controller.dart';
import 'package:yalla_talabat_customer/state/session_controller.dart';

import 'support/test_app.dart';

const L10n _l10n = L10n(true);

const _profile = CustomerProfile(
  id: 'cus_1',
  name: 'أحمد علي',
  initials: 'أع',
  phone: '+966500000000',
  email: null,
  language: 'ar',
  avatarUrl: null,
  status: 'active',
  memberSince: '2024-01-01',
  orderCount: 3,
  defaultAddress: null,
);

CatalogRestaurant _restaurant() => const CatalogRestaurant(
      id: 'res_1',
      name: 'شاورما الشام',
      cuisine: 'سوري',
      rating: 4.6,
      ratingCount: 120,
      logoUrl: null,
      bannerUrl: null,
      accepting: true,
      openNow: true,
      statusLabel: 'open',
      prepMinutes: 20,
      distanceKm: 2.4,
      deliveryFeeMinor: 500,
      minOrderMinor: 1000,
      etaMinutes: 25,
      offerCount: 0,
      categories: [],
    );

CatalogMenuItem _dish() => const CatalogMenuItem(
      id: 'item_1',
      restaurantId: 'res_1',
      restaurantName: 'شاورما الشام',
      categoryId: 'cat_1',
      categoryName: 'ساندويتش',
      name: 'شاورما دجاج',
      description: '',
      priceMinor: 4500,
      offerPriceMinor: null,
      offerTitleAr: null,
      offerTitleEn: null,
      offerDiscountPercent: null,
      available: true,
      prepMinutes: 10,
      imageUrls: [],
      calories: null,
      badgeAr: null,
      badgeEn: null,
      optionGroups: [],
    );

FavoriteRecord _restaurantFavorite() => FavoriteRecord(
      id: 'fav_res',
      targetType: 'restaurant',
      targetId: 'res_1',
      createdAt: '2026-11-10T10:00:00.000Z',
      restaurant: _restaurant(),
      menuItem: null,
    );

FavoriteRecord _dishFavorite() => FavoriteRecord(
      id: 'fav_item',
      targetType: 'menu_item',
      targetId: 'item_1',
      createdAt: '2026-11-10T10:00:00.000Z',
      restaurant: null,
      menuItem: _dish(),
    );

class _SignedInSession extends SessionController {
  @override
  Future<CustomerProfile?> build() async => _profile;
}

class _FakeCart extends CartController {
  @override
  Future<CartResponse> build() async => const CartResponse(
        cartId: null,
        restaurantId: null,
        restaurantName: null,
        lines: [],
        itemCount: 0,
        updatedAt: null,
        quote: null,
      );
}

class _FakeFavorites extends FavoritesController {
  _FakeFavorites(this._records);

  final List<FavoriteRecord> _records;

  @override
  Future<List<FavoriteRecord>> build() async => _records;
}

Future<void> _pumpFavorites(
  WidgetTester tester, {
  List<FavoriteRecord> records = const [],
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    testApp(
      const FavoritesScreen(),
      overrides: [
        sessionProvider.overrideWith(_SignedInSession.new),
        cartProvider.overrideWith(_FakeCart.new),
        favoritesProvider.overrideWith(() => _FakeFavorites(records)),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saved restaurants render as flat cards with a menu action', (
    tester,
  ) async {
    await _pumpFavorites(
      tester,
      records: [_restaurantFavorite(), _dishFavorite()],
    );

    expect(tester.takeException(), isNull);
    expect(find.text(_l10n.favorites), findsOneWidget);
    expect(find.text(_l10n.favoritesSubtitle), findsOneWidget);
    expect(find.text('${_l10n.food} (1)'), findsOneWidget);
    expect(find.text('${_l10n.dishes} (1)'), findsOneWidget);

    expect(find.byType(FavoriteRestaurantCard), findsOneWidget);
    expect(find.text('شاورما الشام'), findsOneWidget);
    expect(find.text(_l10n.menu), findsOneWidget);
    expect(find.text(_l10n.openNow), findsOneWidget);

    final cta = find.descendant(
      of: find.byType(FavoriteRestaurantCard),
      matching: find.byType(OutlinedButton),
    );
    expect(cta, findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FavoriteRestaurantCard),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );
    expect(tester.getSize(cta).width, greaterThanOrEqualTo(132));
  });

  testWidgets('saved dishes render with their restaurant and a view action', (
    tester,
  ) async {
    await _pumpFavorites(
      tester,
      records: [_restaurantFavorite(), _dishFavorite()],
    );

    await tester.tap(find.text('${_l10n.dishes} (1)'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoriteDishCard), findsOneWidget);
    expect(find.text('شاورما دجاج'), findsOneWidget);
    expect(find.text('10 ${_l10n.minutesLong}'), findsOneWidget);
    expect(find.byType(PriceText), findsOneWidget);
    expect(find.text(_l10n.viewDish), findsOneWidget);
    expect(find.text(_l10n.menu), findsNothing);

    final cta = find.descendant(
      of: find.byType(FavoriteDishCard),
      matching: find.byType(OutlinedButton),
    );
    expect(cta, findsOneWidget);
    expect(tester.getSize(cta).width, greaterThanOrEqualTo(132));
  });

  testWidgets('the selected tab is the only filled segment', (tester) async {
    await _pumpFavorites(tester, records: [_restaurantFavorite()]);

    List<Color?> segmentColors() => tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(SegmentedTabs),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((segment) => (segment.decoration as BoxDecoration?)?.color)
        .toList();

    expect(segmentColors(), [
      AppColors.primaryContainer,
      AppColors.surfaceContainerLowest,
    ]);

    await tester.tap(find.text('${_l10n.dishes} (0)'));
    await tester.pumpAndSettle();

    expect(segmentColors(), [
      AppColors.surfaceContainerLowest,
      AppColors.primaryContainer,
    ]);
  });

  testWidgets('the restaurant tab has its own empty panel', (tester) async {
    await _pumpFavorites(tester);

    expect(find.byType(FlatEmptyState), findsOneWidget);
    expect(find.text(_l10n.favoriteRestaurantsTitle), findsOneWidget);
    expect(find.text(_l10n.noFavoriteRestaurants), findsOneWidget);
    expect(find.text(_l10n.browseRestaurants), findsOneWidget);
  });

  testWidgets('the dish tab has its own empty copy', (tester) async {
    await _pumpFavorites(tester);

    await tester.tap(find.text('${_l10n.dishes} (0)'));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.favoriteItemsTitle), findsOneWidget);
    expect(find.text(_l10n.noFavoriteItems), findsOneWidget);
  });

  testWidgets('uses flat surfaces: no shadows or gradients', (tester) async {
    await _pumpFavorites(
      tester,
      records: [_restaurantFavorite(), _dishFavorite()],
    );

    final containers = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(FavoritesScreen),
        matching: find.byType(Container),
      ),
    );
    for (final container in containers) {
      final decoration = container.decoration;
      if (decoration is BoxDecoration) {
        expect(decoration.boxShadow, isNull);
        expect(decoration.gradient, isNull);
      }
    }
  });
}
