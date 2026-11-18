import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/design/app_colors.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/core/widgets/flat_empty_state.dart';
import 'package:yalla_talabat_customer/data/models/cart.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/data/models/orders.dart';
import 'package:yalla_talabat_customer/presentation/orders/orders_screen.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/order_card.dart';
import 'package:yalla_talabat_customer/presentation/orders/widgets/orders_tabs.dart';
import 'package:yalla_talabat_customer/state/cart_controller.dart';
import 'package:yalla_talabat_customer/state/orders_controller.dart';
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

OrderSummary _summary({
  required String id,
  required String reference,
  required String status,
  required String statusLabelAr,
  required int totalMinor,
  bool canRate = false,
  bool canReorder = false,
}) {
  return OrderSummary(
    id: id,
    reference: reference,
    restaurantId: 'res_1',
    restaurantName: 'شاورما الشام',
    restaurantLogoUrl: null,
    status: status,
    statusLabelAr: statusLabelAr,
    statusLabelEn: status,
    paymentStatus: 'paid',
    paymentMethod: 'cash_on_delivery',
    totalMinor: totalMinor,
    currency: 'SDG',
    itemCount: 2,
    placedAt: '2026-11-14T12:30:00.000Z',
    deliveredAt: null,
    canCancel: false,
    canRate: canRate,
    canReorder: canReorder,
  );
}

final _activeOrders = OrdersState(
  items: [
    _summary(
      id: 'ord_active',
      reference: 'ORD-1001',
      status: 'preparing',
      statusLabelAr: 'قيد التحضير',
      totalMinor: 12500,
    ),
  ],
  hasMore: false,
  page: 1,
  total: 1,
);

final _pastOrders = OrdersState(
  items: [
    _summary(
      id: 'ord_delivered',
      reference: 'ORD-1002',
      status: 'delivered',
      statusLabelAr: 'تم التوصيل',
      totalMinor: 8700,
      canRate: true,
      canReorder: true,
    ),
    _summary(
      id: 'ord_cancelled',
      reference: 'ORD-1003',
      status: 'cancelled',
      statusLabelAr: 'ملغي',
      totalMinor: 5400,
    ),
  ],
  hasMore: false,
  page: 1,
  total: 2,
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

class _FakeOrders extends OrdersController {
  _FakeOrders({OrdersState? active, OrdersState? past})
      : _active = active ?? OrdersState.empty,
        _past = past ?? OrdersState.empty;

  final OrdersState _active;
  final OrdersState _past;

  @override
  Future<OrdersState> build(OrdersTab tab) async =>
      tab == OrdersTab.active ? _active : _past;
}

Future<void> _pumpOrders(
  WidgetTester tester, {
  OrdersState? active,
  OrdersState? past,
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    testApp(
      const OrdersScreen(),
      overrides: [
        sessionProvider.overrideWith(_SignedInSession.new),
        cartProvider.overrideWith(_FakeCart.new),
        ordersProvider.overrideWith(
          () => _FakeOrders(active: active, past: past),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('active orders render as flat cards with a track action', (
    tester,
  ) async {
    await _pumpOrders(tester, active: _activeOrders);

    expect(tester.takeException(), isNull);
    expect(find.text(_l10n.myOrders), findsOneWidget);
    expect(find.text(_l10n.ordersSubtitle), findsOneWidget);
    expect(find.text(_l10n.activeOrders), findsOneWidget);
    expect(find.text(_l10n.pastOrders), findsOneWidget);

    expect(find.byType(OrderCard), findsOneWidget);
    expect(find.text('شاورما الشام'), findsOneWidget);
    expect(find.text('ORD-1001'), findsOneWidget);
    expect(find.text('قيد التحضير'), findsOneWidget);
    expect(find.text('125 SDG'), findsOneWidget);
    expect(find.text('2 ${_l10n.items}'), findsOneWidget);
    expect(find.text(_l10n.track), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);

    // The track action is outlined (not filled) and sized like a real button.
    final cta = find.descendant(
      of: find.byType(OrderCard),
      matching: find.byType(OutlinedButton),
    );
    expect(cta, findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OrderCard),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );
    expect(tester.getSize(cta).width, greaterThanOrEqualTo(132));
  });

  testWidgets('past orders offer reorder or view order per backend flags', (
    tester,
  ) async {
    await _pumpOrders(
      tester,
      active: _activeOrders,
      past: _pastOrders,
    );

    await tester.tap(find.text(_l10n.pastOrders));
    await tester.pumpAndSettle();

    expect(find.byType(OrderCard), findsNWidgets(2));
    expect(find.text(_l10n.reorder), findsOneWidget);
    expect(find.text(_l10n.viewOrder), findsOneWidget);
    expect(find.text(_l10n.track), findsNothing);
    expect(find.byIcon(Icons.star_outline), findsOneWidget);
  });

  testWidgets('the selected tab is the only filled segment', (tester) async {
    await _pumpOrders(tester, active: _activeOrders);

    List<Color?> segmentColors() => tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(OrdersTabs),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((segment) => (segment.decoration as BoxDecoration?)?.color)
        .toList();

    expect(segmentColors(), [
      AppColors.primaryContainer,
      AppColors.surfaceContainerLowest,
    ]);

    await tester.tap(find.text(_l10n.pastOrders));
    await tester.pumpAndSettle();

    expect(segmentColors(), [
      AppColors.surfaceContainerLowest,
      AppColors.primaryContainer,
    ]);
  });

  testWidgets('shows the active empty state with a browse action', (
    tester,
  ) async {
    await _pumpOrders(tester, active: OrdersState.empty);

    expect(find.text(_l10n.noActiveOrders), findsOneWidget);
    expect(find.text(_l10n.noActiveOrdersMessage), findsOneWidget);
    expect(find.text(_l10n.browseRestaurants), findsOneWidget);
    expect(find.byType(FlatEmptyState), findsOneWidget);
  });

  testWidgets('the past tab has its own empty copy', (tester) async {
    await _pumpOrders(tester, active: _activeOrders, past: OrdersState.empty);

    await tester.tap(find.text(_l10n.pastOrders));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.noPastOrders), findsOneWidget);
    expect(find.text(_l10n.noPastOrdersMessage), findsOneWidget);
  });

  testWidgets('uses flat surfaces: no shadows or gradients', (tester) async {
    await _pumpOrders(tester, active: _activeOrders);

    final containers = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(OrdersScreen),
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
