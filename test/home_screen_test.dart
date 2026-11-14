import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/localization/app_localizations.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/presentation/home/home_screen.dart';
import 'package:yalla_talabat_customer/state/home_controller.dart';
import 'package:yalla_talabat_customer/state/session_controller.dart';

/// Deterministic guest session: no secure-storage plugin in widget tests.
class _GuestSession extends SessionController {
  @override
  Future<CustomerProfile?> build() async => null;
}

/// Serves a fixed home payload so the screen composition can be asserted
/// without any network access.
class _FakeHome extends HomeController {
  _FakeHome(this.payload);

  final CatalogHome payload;

  @override
  Future<CatalogHome> build() async => payload;
}

CatalogRestaurant _restaurant(String id, String name) {
  return CatalogRestaurant(
    id: id,
    name: name,
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
    categories: const ['cat_1'],
  );
}

HomeService _service(String key, String titleAr, {bool enabled = true}) {
  return HomeService(key: key, enabled: enabled, titleAr: titleAr, titleEn: key);
}

CatalogBanner _banner() {
  return const CatalogBanner(
    id: 'bnr_1',
    titleAr: 'خصم 25% على أول طلب',
    titleEn: '25% off your first order',
    subtitleAr: '',
    subtitleEn: '',
    imageUrl: '',
    targetType: 'restaurant',
    targetId: 'r_1',
    externalUrl: null,
    position: 1,
  );
}

CatalogHome _home({
  List<HomeService> services = const [],
  List<CatalogBanner> banners = const [],
  List<CatalogRestaurant> nearby = const [],
  List<CatalogRestaurant> restaurants = const [],
}) {
  return CatalogHome(
    sections: const [],
    services: services,
    banners: banners,
    offers: const [],
    nearby: nearby,
    bestSellers: const [],
    restaurants: restaurants,
    categories: const [],
    address: null,
    eligibility: null,
  );
}

Widget _app(CatalogHome payload, {Locale locale = const Locale('ar')}) {
  return ProviderScope(
    overrides: [
      sessionProvider.overrideWith(_GuestSession.new),
      homeProvider.overrideWith(() => _FakeHome(payload)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppMaterialLocalizationsDelegate(),
        AppCupertinoLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen composition', () {
    testWidgets('renders the design service strip, banner and nearby list',
        (tester) async {
      final payload = _home(
        services: [
          _service('food', 'المطاعم'),
          _service('parcel', 'الطرود', enabled: false),
        ],
        banners: [_banner()],
        nearby: [_restaurant('r_1', 'مطعم الاختبار')],
        restaurants: [_restaurant('r_1', 'مطعم الاختبار')],
      );

      await tester.pumpWidget(_app(payload));
      await tester.pumpAndSettle();

      expect(find.text('المطاعم'), findsOneWidget);
      expect(find.text('طلبات مارت'), findsOneWidget);
      expect(find.text('البقالة'), findsOneWidget);
      expect(find.text('DineOut'), findsOneWidget);
      expect(find.text('صيدلية'), findsOneWidget);
      expect(find.text('خصم 25% على أول طلب'), findsOneWidget);
      expect(find.text(const L10n(true).restaurantsNearYou), findsOneWidget);
      expect(find.text('مطعم الاختبار'), findsWidgets);

      final direction = Directionality.of(
        tester.element(find.text(const L10n(true).restaurantsNearYou)),
      );
      expect(direction, TextDirection.rtl);
    });

    testWidgets('shows a snackbar when a disabled service is tapped',
        (tester) async {
      final payload = _home(
        services: [_service('food', 'المطاعم')],
        restaurants: [_restaurant('r_1', 'مطعم الاختبار')],
      );

      await tester.pumpWidget(_app(payload));
      await tester.pumpAndSettle();

      await tester.tap(find.text('البقالة'));
      await tester.pump();

      expect(find.text(const L10n(true).serviceUnavailable), findsOneWidget);
    });

    testWidgets('falls back to restaurants when nearby is empty',
        (tester) async {
      final payload = _home(
        restaurants: [_restaurant('r_2', 'مطعم بديل')],
      );

      await tester.pumpWidget(_app(payload));
      await tester.pumpAndSettle();

      expect(find.text(const L10n(true).restaurantsNearYou), findsOneWidget);
      expect(find.text('مطعم بديل'), findsWidgets);
    });

    testWidgets('hides offer and best-seller sections without data',
        (tester) async {
      final payload = _home(
        restaurants: [_restaurant('r_1', 'مطعم الاختبار')],
      );

      await tester.pumpWidget(_app(payload));
      await tester.pumpAndSettle();

      expect(find.text(const L10n(true).exclusiveOffers), findsNothing);
      expect(find.text(const L10n(true).bestSellersThisWeek), findsNothing);
    });

    testWidgets('shows the add-address prompt for a guest with no content',
        (tester) async {
      await tester.pumpWidget(_app(_home()));
      await tester.pumpAndSettle();

      expect(find.text(const L10n(true).addAddressToSeeNearby), findsOneWidget);
    });

    testWidgets('renders English copy when the locale is English',
        (tester) async {
      final payload = _home(
        services: [_service('food', 'Restaurants')],
        restaurants: [_restaurant('r_1', 'Test restaurant')],
      );

      await tester.pumpWidget(_app(payload, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text(const L10n(false).restaurantsNearYou), findsOneWidget);
    });

    testWidgets('keeps the design section order top to bottom', (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final payload = CatalogHome(
        sections: const [],
        services: [_service('food', 'المطاعم')],
        banners: [_banner()],
        offers: [_offer()],
        nearby: [_restaurant('r_1', 'مطعم الاختبار')],
        bestSellers: [_menuItem()],
        restaurants: [_restaurant('r_1', 'مطعم الاختبار')],
        categories: const [],
        address: null,
        eligibility: null,
      );

      await tester.pumpWidget(_app(payload));
      await tester.pumpAndSettle();

      final l10n = const L10n(true);
      final services = tester.getTopLeft(find.text('المطاعم')).dy;
      final banner = tester.getTopLeft(find.text('خصم 25% على أول طلب')).dy;
      final offers = tester.getTopLeft(find.text(l10n.exclusiveOffers)).dy;
      final nearby = tester.getTopLeft(find.text(l10n.restaurantsNearYou)).dy;
      final best = tester.getTopLeft(find.text(l10n.bestSellersThisWeek)).dy;

      expect(services, lessThan(banner));
      expect(banner, lessThan(offers));
      expect(offers, lessThan(nearby));
      expect(nearby, lessThan(best));
    });

    testWidgets('uses a flat white surface without card shadows',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final payload = CatalogHome(
        sections: const [],
        services: [_service('food', 'المطاعم')],
        banners: [_banner()],
        offers: [_offer()],
        nearby: [_restaurant('r_1', 'مطعم الاختبار')],
        bestSellers: [_menuItem()],
        restaurants: [_restaurant('r_1', 'مطعم الاختبار')],
        categories: const [],
        address: null,
        eligibility: null,
      );

      await tester.pumpWidget(_app(payload));
      await tester.pumpAndSettle();

      for (final element in find.byType(Container).evaluate()) {
        final decoration = (element.widget as Container).decoration;
        if (decoration is BoxDecoration) {
          expect(decoration.boxShadow, isNull);
        }
      }
      expect(find.byType(Scaffold), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor ?? const Color(0xFFFFFFFF),
        const Color(0xFFFFFFFF),
      );
    });
  });
}

CatalogOffer _offer() {
  return CatalogOffer(
    id: 'off_1',
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
    items: const [
      CatalogOfferItem(
        menuItemId: 'item_1',
        name: 'صنف',
        nameAr: 'صنف',
        nameEn: 'Item',
        imageUrl: null,
        priceMinor: 2500,
        offerPriceMinor: 2000,
        discountPercent: 10,
      ),
    ],
  );
}

CatalogMenuItem _menuItem() {
  return const CatalogMenuItem(
    id: 'item_1',
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
    imageUrls: [],
    calories: null,
    badgeAr: null,
    badgeEn: null,
    optionGroups: [],
  );
}
