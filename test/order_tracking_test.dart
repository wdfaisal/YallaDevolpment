import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/design/app_colors.dart';
import 'package:yalla_talabat_customer/core/design/app_spacing.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/data/models/cart.dart';
import 'package:yalla_talabat_customer/data/models/maps.dart';
import 'package:yalla_talabat_customer/data/models/orders.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/tracking_driver_card.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/tracking_map_hero.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/tracking_order_summary.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/tracking_route_card.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/tracking_safety_card.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/tracking_timeline.dart';

import 'support/test_app.dart';

OrderDetail _detail({String status = 'en_route_to_customer'}) {
  final active =
      !const {'delivered', 'cancelled', 'failed_delivery'}.contains(status);
  return OrderDetail(
    summary: OrderSummary(
      id: 'ord_1',
      reference: 'YT-1001',
      restaurantId: 'res_1',
      restaurantName: 'برجر بوتيك',
      restaurantLogoUrl: null,
      status: status,
      statusLabelAr: active ? 'السائق في الطريق' : 'تم التوصيل',
      statusLabelEn: active ? 'On the way' : 'Delivered',
      paymentStatus: 'paid',
      paymentMethod: 'wallet',
      totalMinor: 8280,
      currency: 'SAR',
      itemCount: 2,
      placedAt: '2026-11-14T18:15:00Z',
      deliveredAt: active ? null : '2026-11-14T18:45:00Z',
      canCancel: false,
      canRate: !active,
      canReorder: true,
    ),
    items: const [
      OrderItemLine(
        id: 'item_1',
        menuItemId: 'menu_1',
        name: 'ترفل سجنتشر برجر',
        quantity: 1,
        unitPriceMinor: 5400,
        lineTotalMinor: 5400,
        options: '',
        notes: '',
      ),
      OrderItemLine(
        id: 'item_2',
        menuItemId: 'menu_2',
        name: 'بطاطس وافل',
        quantity: 1,
        unitPriceMinor: 1800,
        lineTotalMinor: 1800,
        options: '',
        notes: '',
      ),
    ],
    subtotalMinor: 7200,
    deliveryFeeMinor: 0,
    vatMinor: 1080,
    discountMinor: 0,
    deliveryAddress: 'حي النرجس، الرياض',
    deliveryPosition: const GeoPoint(lat: 15.55, lng: 32.5),
    restaurantPosition: const GeoPoint(lat: 15.5073, lng: 32.5607),
    note: '',
    couponCode: null,
    payments: const [
      PaymentPart(
        id: 'pay_1',
        method: 'wallet',
        amountMinor: 8280,
        status: 'paid',
        reference: 'W-1',
      ),
    ],
    tracking: OrderTracking(
      status: status,
      driver: active
          ? const DriverTracking(
              id: 'drv_1',
              name: 'محمد عبدالله',
              initials: 'م ع',
              vehicle: 'هوندا أحمر',
              plate: 'أ ب ج ١٢٣٤',
              rating: 4.8,
              phone: '+966500000000',
              position: GeoPoint(lat: 15.53, lng: 32.53),
              lastSignalAt: '2026-11-14T18:40:00Z',
              stale: false,
            )
          : null,
      etaMinutes: active ? 12 : null,
      events: [
        const TimelineEvent(
          id: 'evt_1',
          time: '2026-11-14T18:15:00Z',
          at: '2026-11-14T18:15:00Z',
          title: 'تم تأكيد الطلب بنجاح',
          detail: 'المطعم استلم طلبك وبدأ بالتجهيز',
          actor: 'system',
          state: 'done',
        ),
        TimelineEvent(
          id: 'evt_2',
          time: '2026-11-14T18:40:00Z',
          at: '2026-11-14T18:40:00Z',
          title: active ? 'السائق في الطريق إليك' : 'تم التسليم',
          detail: active ? 'الكابتن استلم الوجبة' : 'بالعافية',
          actor: 'driver',
          state: 'done',
        ),
      ],
    ),
    rating: active ? null : const OrderRating(restaurant: 5, driver: 4),
    scheduledFor: null,
    fulfillment: 'delivery',
  );
}

void _expectNoBoxShadows(WidgetTester tester) {
  for (final container
      in tester.widgetList<Container>(find.byType(Container))) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration) {
      expect(decoration.boxShadow, isNull);
    }
  }
}

void main() {
  const l10n = L10n(true);

  testWidgets('map hero shows the live ETA, route and recenter control', (
    tester,
  ) async {
    var back = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingMapHero(
            detail: _detail(),
            l10n: l10n,
            height: 360,
            onBack: () => back++,
            loadTiles: false,
            animatePulse: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('12'), findsWidgets);
    expect(find.text('برجر بوتيك'), findsOneWidget);
    expect(find.text('حي النرجس'), findsOneWidget);
    expect(find.textContaining(l10n.movingNow), findsOneWidget);
    expect(find.byTooltip(l10n.recenterMap), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.recenterMap));
    expect(back, 0);
    // Without a cancellable order the header row keeps just the title.
    expect(find.text(l10n.cancelOrder), findsNothing);
    // The back button uses the auto-mirrored arrow, which points right in RTL.
    final backIcon = find.byIcon(Icons.arrow_back);
    expect(backIcon, findsOneWidget);
    expect(
      Directionality.of(tester.element(backIcon)),
      TextDirection.rtl,
    );
    _expectNoBoxShadows(tester);
  });

  testWidgets('the title keeps its pill and cancel shares its row, smaller', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var cancelled = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingMapHero(
            detail: _detail(),
            l10n: l10n,
            height: 360,
            onBack: () {},
            onCancel: () => cancelled++,
            loadTiles: false,
            animatePulse: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final title = find.text(l10n.trackOrderTitle);
    expect(title, findsOneWidget);
    // The title sits on a flat white pill again.
    final pill = tester.widget<Container>(
      find.ancestor(of: title, matching: find.byType(Container)).first,
    );
    expect(
      (pill.decoration! as BoxDecoration).color,
      AppColors.surfaceContainerLowest,
    );

    final cancel = find.text(l10n.cancelOrder);
    expect(cancel, findsOneWidget);
    // Cancel uses a smaller label than the title and stays on its row.
    expect(
      tester.widget<Text>(cancel).style!.fontSize,
      lessThan(tester.widget<Text>(title).style!.fontSize!),
    );
    expect(
      tester.getCenter(cancel).dy,
      moreOrLessEquals(tester.getCenter(title).dy, epsilon: 1),
    );

    // Outlined rectangle: transparent fill with a red border, pinned to the
    // left edge of the screen (the end side in RTL).
    final boxFinder =
        find.ancestor(of: cancel, matching: find.byType(Container)).first;
    final box = tester.widget<Container>(boxFinder);
    final boxDecoration = box.decoration! as BoxDecoration;
    expect(boxDecoration.color, isNull);
    expect(boxDecoration.border, isNotNull);
    expect(
      boxDecoration.borderRadius,
      BorderRadius.circular(AppSpacing.radiusSm),
    );
    expect(
      tester.getTopLeft(boxFinder).dx,
      moreOrLessEquals(AppSpacing.lg, epsilon: 1),
    );

    await tester.tap(cancel);
    expect(cancelled, 1);
    _expectNoBoxShadows(tester);
  });

  testWidgets('map hero falls back when no coordinates are available', (
    tester,
  ) async {
    final base = _detail();
    final noCoords = OrderDetail(
      summary: base.summary,
      items: base.items,
      subtotalMinor: base.subtotalMinor,
      deliveryFeeMinor: base.deliveryFeeMinor,
      vatMinor: base.vatMinor,
      discountMinor: base.discountMinor,
      deliveryAddress: base.deliveryAddress,
      deliveryPosition: null,
      restaurantPosition: null,
      note: base.note,
      couponCode: base.couponCode,
      payments: base.payments,
      tracking: OrderTracking(
        status: base.tracking.status,
        driver: null,
        etaMinutes: null,
        events: base.tracking.events,
      ),
      rating: base.rating,
      scheduledFor: base.scheduledFor,
      fulfillment: base.fulfillment,
    );
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingMapHero(
            detail: noCoords,
            l10n: l10n,
            height: 360,
            onBack: () {},
            loadTiles: false,
            animatePulse: false,
          ),
        ),
      ),
    );

    expect(find.text(l10n.mapUnavailable), findsOneWidget);
    _expectNoBoxShadows(tester);
  });

  testWidgets('map hero draws the provider road geometry, not a straight line',
      (
    tester,
  ) async {
    const route = MapRoute(
      distanceKm: 13.89,
      durationMin: 22,
      points: [
        GeoPoint(lat: 15.5075, lng: 32.5606),
        GeoPoint(lat: 15.5200, lng: 32.5450),
        GeoPoint(lat: 15.5350, lng: 32.5200),
        GeoPoint(lat: 15.5499, lng: 32.5000),
      ],
    );
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingMapHero(
            detail: _detail(),
            l10n: l10n,
            height: 360,
            onBack: () {},
            loadTiles: false,
            animatePulse: false,
            route: route,
          ),
        ),
      ),
    );
    await tester.pump();

    final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(layer.polylines, hasLength(1));
    // The polyline follows every provider point instead of the two markers.
    expect(layer.polylines.single.points, hasLength(route.points.length));
  });

  testWidgets('route card shows the provider distance and time', (
    tester,
  ) async {
    const route = MapRoute(
      distanceKm: 13.89,
      durationMin: 22,
      points: [
        GeoPoint(lat: 15.5075, lng: 32.5606),
        GeoPoint(lat: 15.5499, lng: 32.5000),
      ],
    );
    await tester.pumpWidget(
      testApp(
        Scaffold(body: TrackingRouteCard(route: route, l10n: l10n)),
      ),
    );

    expect(find.text(l10n.routeDistanceLabel), findsOneWidget);
    expect(find.text('13.9 ${l10n.km}'), findsOneWidget);
    expect(find.text(l10n.routeDurationLabel), findsOneWidget);
    expect(find.text('22 ${l10n.minutesLong}'), findsOneWidget);
    _expectNoBoxShadows(tester);
  });

  testWidgets('timeline marks the current step and the pending delivery', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingTimeline(detail: _detail(), l10n: l10n),
        ),
      ),
    );

    expect(find.text(l10n.currentOrderStatus), findsOneWidget);
    expect(find.text(l10n.inProgress), findsOneWidget);
    expect(find.text('تم تأكيد الطلب بنجاح'), findsOneWidget);
    expect(find.text('السائق في الطريق إليك'), findsOneWidget);
    expect(find.text(l10n.deliveredAndReceived), findsOneWidget);
    expect(find.text(l10n.deliveredSoonDetail), findsOneWidget);
    expect(find.text(l10n.deliverySoon), findsOneWidget);
    _expectNoBoxShadows(tester);
  });

  testWidgets('delivered order hides the pending step', (tester) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingTimeline(
            detail: _detail(status: 'delivered'),
            l10n: l10n,
          ),
        ),
      ),
    );

    expect(find.text(l10n.deliverySoon), findsNothing);
    expect(find.text(l10n.delivered), findsOneWidget);
  });

  testWidgets('driver card exposes call and support actions', (tester) async {
    var called = 0;
    var supported = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingDriverCard(
            driver: _detail().tracking.driver!,
            l10n: l10n,
            onCall: () => called++,
            onSupport: () => supported++,
          ),
        ),
      ),
    );

    expect(find.text('محمد عبدالله'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    await tester.tap(find.text(l10n.callDriver));
    await tester.tap(find.text(l10n.support));
    expect(called, 1);
    expect(supported, 1);
    _expectNoBoxShadows(tester);
  });

  testWidgets('summary shows live items, totals and collapses', (tester) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: TrackingOrderSummary(
            detail: _detail(),
            l10n: l10n,
            onShareReceipt: () {},
            onSupport: () {},
          ),
        ),
      ),
    );

    expect(find.text('ترفل سجنتشر برجر'), findsOneWidget);
    expect(find.text('بطاطس وافل'), findsOneWidget);
    expect(find.text('82.80 SAR'), findsOneWidget);
    expect(find.text(l10n.totalPaid), findsOneWidget);

    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(rotation.turns, 0.5);
    await tester.tap(find.text(l10n.orderDetails));
    await tester.pumpAndSettle();
    final collapsed = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(collapsed.turns, 0);
    _expectNoBoxShadows(tester);
  });

  testWidgets('safety card renders the guarantee copy', (tester) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(body: TrackingSafetyCard(l10n: l10n)),
      ),
    );

    expect(find.text(l10n.safetyGuaranteeTitle), findsOneWidget);
    expect(find.text(l10n.safetyGuaranteeBody), findsOneWidget);
    _expectNoBoxShadows(tester);
  });
}
