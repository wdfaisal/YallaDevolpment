import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/widgets/app_image.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/presentation/home/widgets/home_banner.dart';
import 'package:yalla_talabat_customer/presentation/home/widgets/home_best_sellers.dart';
import 'package:yalla_talabat_customer/presentation/home/widgets/home_nearby.dart';
import 'package:yalla_talabat_customer/presentation/home/widgets/home_offers.dart';
import 'package:yalla_talabat_customer/presentation/home/widgets/home_section_header.dart';
import 'package:yalla_talabat_customer/presentation/home/widgets/home_services.dart';

import 'support/test_app.dart';

CatalogBanner _banner({
  String titleAr = 'عرض تجريبي',
  String targetType = 'none',
  String imageUrl = '',
}) {
  return CatalogBanner(
    id: 'bnr_1',
    titleAr: titleAr,
    titleEn: 'Demo offer',
    subtitleAr: '',
    subtitleEn: '',
    imageUrl: imageUrl,
    targetType: targetType,
    targetId: null,
    externalUrl: null,
    position: 1,
  );
}

HomeService _service(String key, String titleAr, {bool enabled = true}) {
  return HomeService(
    key: key,
    enabled: enabled,
    titleAr: titleAr,
    titleEn: key,
  );
}

void main() {
  group('HomeSectionHeader', () {
    testWidgets('renders the title and trailing action', (tester) async {
      await tester.pumpWidget(
        testApp(
          const HomeSectionHeader(
            title: 'مطاعم بالقرب منك',
            trailing: Text('عرض الكل'),
          ),
        ),
      );

      expect(find.text('مطاعم بالقرب منك'), findsOneWidget);
      expect(find.text('عرض الكل'), findsOneWidget);
    });
  });

  group('HomeServices', () {
    testWidgets('renders the five design tiles and reports the tapped service',
        (tester) async {
      HomeService? selected;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: HomeServices(
              services: [
                _service('food', 'المطاعم'),
                _service('parcel', 'الطرود', enabled: false),
              ],
              onSelected: (service) => selected = service,
            ),
          ),
        ),
      );

      expect(find.text('المطاعم'), findsOneWidget);
      expect(find.text('طلبات مارت'), findsOneWidget);
      expect(find.text('البقالة'), findsOneWidget);
      expect(find.text('DineOut'), findsOneWidget);
      expect(find.text('صيدلية'), findsOneWidget);
      expect(find.text('سريع'), findsOneWidget);
      expect(find.text('جديد'), findsOneWidget);

      await tester.tap(find.text('المطاعم'));
      expect(selected?.key, 'food');
      expect(selected?.enabled, isTrue);

      await tester.tap(find.text('البقالة'));
      expect(selected?.key, 'grocery');
      expect(selected?.enabled, isFalse);
    });

    testWidgets('renders nothing when no service is enabled', (tester) async {
      await tester.pumpWidget(
        testApp(
          const Scaffold(
            body: HomeServices(services: [], onSelected: _noop),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('HomeBanner', () {
    testWidgets('renders backend content and opens the target', (tester) async {
      CatalogBanner? tapped;
      final banner = _banner();
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: HomeBanner(
              banners: [banner],
              onTap: (value) => tapped = value,
            ),
          ),
        ),
      );

      expect(find.text('عرض تجريبي'), findsOneWidget);
      expect(find.text('اطلب الآن'), findsOneWidget);

      await tester.tap(find.text('اطلب الآن'));
      expect(tapped?.id, banner.id);
    });

    testWidgets('backend image fills the whole banner surface', (tester) async {
      final banner = _banner(imageUrl: 'https://example.com/banner.jpg');
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 440,
                child: HomeBanner(banners: [banner], onTap: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final size = tester.getSize(find.byType(HomeBanner));
      expect(size.width, 440);
      expect(size.height, closeTo(440 / 2.2, 0.5));

      final image = tester.widget<AppImage>(find.byType(AppImage));
      expect(image.fit, BoxFit.cover);
      expect(image.width, double.infinity);
      expect(image.height, double.infinity);
    });
  });

  group('HomeOffers', () {
    testWidgets('lays out one-item and three-item cards without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final restaurant = _restaurant();
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: HomeOffers(
                offers: [
                  _offer('off_1', 1),
                  _offer('off_2', 3),
                ],
                restaurants: {restaurant.id: restaurant},
                onRestaurantTap: (_) {},
                onItemTap: (_, __) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('عروض حصرية اليوم'), findsOneWidget);
      expect(find.text('أبرز عروض الخصم'), findsOneWidget);
      expect(find.text('3 أصناف مخفضة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps products on one row and scrolls the extras',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final restaurant = _restaurant();
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: HomeOffers(
                offers: [
                  _offer('off_1', 2),
                  _offer('off_2', 4),
                ],
                restaurants: {restaurant.id: restaurant},
                onRestaurantTap: (_) {},
                onItemTap: (_, __) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The card is a little wider than the 320px design card.
      expect(tester.getSize(find.byType(HomeOfferCard).first).width,
          greaterThan(320));

      // Two products of the same offer share one row.
      final twoItemsFirst = tester.getTopLeft(find.text('صنف 0').at(0));
      final twoItemsSecond = tester.getTopLeft(find.text('صنف 1').at(0));
      expect(twoItemsSecond.dy, twoItemsFirst.dy);

      // Four products stay on one row; the fourth scrolls sideways instead of
      // wrapping to a second line.
      final fourItemsFirst = tester.getTopLeft(find.text('صنف 0').at(1));
      final fourItemsFourth = tester.getTopLeft(find.text('صنف 3'));
      expect(fourItemsFourth.dy, fourItemsFirst.dy);
      expect(fourItemsFourth.dx, isNot(fourItemsFirst.dx));
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeNearby', () {
    testWidgets('switches between the list and grid layouts', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var grid = false;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: HomeNearby(
                  restaurants: [_restaurant(id: 'r_1')],
                  isGrid: grid,
                  onToggleGrid: (value) => setState(() => grid = value),
                  onSeeAll: () {},
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('عرض الكل (1)'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeBestSellers', () {
    testWidgets('lays out the two-column grid without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: HomeBestSellers(
                items: [_menuItem('m_1'), _menuItem('m_2')],
                onTap: (_) {},
                onAdd: (_) {},
                onMore: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الأكثر طلباً هذا الأسبوع'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

CatalogRestaurant _restaurant({String id = 'r_1'}) {
  return CatalogRestaurant(
    id: id,
    name: 'مطعم الاختبار',
    cuisine: 'مشويات',
    rating: 4.6,
    ratingCount: 120,
    logoUrl: null,
    bannerUrl: null,
    accepting: true,
    openNow: true,
    statusLabel: 'open',
    prepMinutes: 20,
    distanceKm: 1.2,
    deliveryFeeMinor: 500,
    minOrderMinor: 1000,
    etaMinutes: 30,
    offerCount: 1,
    categories: const [],
  );
}

CatalogOffer _offer(String id, int itemCount) {
  return CatalogOffer(
    id: id,
    restaurantId: 'r_1',
    restaurantName: 'مطعم الاختبار',
    titleAr: 'عرض',
    titleEn: 'Offer',
    descriptionAr: '',
    descriptionEn: '',
    imageUrl: null,
    discountType: 'percentage',
    discountValue: 10,
    endsAt: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
    items: [
      for (var index = 0; index < itemCount; index++)
        CatalogOfferItem(
          menuItemId: 'item_$index',
          name: 'صنف $index',
          nameAr: 'صنف $index',
          nameEn: 'Item $index',
          imageUrl: null,
          priceMinor: 2500,
          offerPriceMinor: 2000,
          discountPercent: 10,
        ),
    ],
  );
}

CatalogMenuItem _menuItem(String id) {
  return CatalogMenuItem(
    id: id,
    restaurantId: 'r_1',
    restaurantName: 'مطعم الاختبار',
    categoryId: null,
    categoryName: null,
    name: 'صنف شائع',
    description: '',
    priceMinor: 1900,
    offerPriceMinor: null,
    offerTitleAr: null,
    offerTitleEn: null,
    offerDiscountPercent: null,
    available: true,
    prepMinutes: 10,
    imageUrls: const [],
    calories: null,
    badgeAr: null,
    badgeEn: null,
    optionGroups: const [],
  );
}

void _noop(HomeService service) {}
