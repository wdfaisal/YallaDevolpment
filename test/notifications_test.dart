import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/data/api/token_store.dart';
import 'package:yalla_talabat_customer/data/models/account.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/presentation/notifications/notifications_screen.dart';
import 'package:yalla_talabat_customer/presentation/notifications/notifications_view_data.dart';
import 'package:yalla_talabat_customer/presentation/notifications/widgets/notification_card.dart';
import 'package:yalla_talabat_customer/presentation/notifications/widgets/notification_empty_state.dart';
import 'package:yalla_talabat_customer/presentation/notifications/widgets/notification_filter_bar.dart';
import 'package:yalla_talabat_customer/presentation/notifications/widgets/notification_group_header.dart';
import 'package:yalla_talabat_customer/presentation/notifications/widgets/notification_settings_card.dart';
import 'package:yalla_talabat_customer/presentation/notifications/widgets/notifications_header.dart';
import 'package:yalla_talabat_customer/state/account_controllers.dart';
import 'package:yalla_talabat_customer/state/providers.dart';
import 'package:yalla_talabat_customer/state/session_controller.dart';

import 'support/test_app.dart';

const _l10n = L10n(true);
final _now = DateTime.now();

CustomerNotification _notification({
  String id = 'ntf_1',
  String kind = 'order',
  String titleAr = 'تم استلام طلبك',
  String titleEn = 'Order received',
  String bodyAr = 'طلبك قيد المراجعة.',
  String bodyEn = 'Your order is being reviewed.',
  Map<String, dynamic>? data,
  String? readAt,
  DateTime? createdAt,
}) {
  return CustomerNotification(
    id: id,
    kind: kind,
    titleAr: titleAr,
    titleEn: titleEn,
    bodyAr: bodyAr,
    bodyEn: bodyEn,
    data: data,
    readAt: readAt,
    createdAt: (createdAt ?? _now).toIso8601String(),
  );
}

NotificationPage _page(List<CustomerNotification> items, {int? unread}) {
  return NotificationPage(
    items: items,
    page: 1,
    pageSize: 30,
    total: items.length,
    hasMore: false,
    unreadCount: unread ?? items.where((item) => item.isUnread).length,
  );
}

void main() {
  group('notifications view data', () {
    test('maps backend kinds to filter categories', () {
      expect(categoryOfKind('order'), NotificationCategory.orders);
      expect(categoryOfKind('offer'), NotificationCategory.offers);
      expect(categoryOfKind('wallet'), NotificationCategory.account);
      expect(categoryOfKind('support'), NotificationCategory.account);
      expect(categoryOfKind('unknown'), isNull);
    });

    test('counts loaded items and keeps the backend total for all', () {
      final page = NotificationPage(
        items: [
          _notification(id: '1', kind: 'order'),
          _notification(id: '2', kind: 'offer'),
          _notification(id: '3', kind: 'wallet'),
          _notification(id: '4', kind: 'unknown'),
        ],
        page: 1,
        pageSize: 30,
        total: 9,
        hasMore: true,
        unreadCount: 4,
      );

      final counts = filterCounts(page);
      expect(counts[NotificationFilter.all], 9);
      expect(counts[NotificationFilter.orders], 1);
      expect(counts[NotificationFilter.offers], 1);
      expect(counts[NotificationFilter.account], 1);
    });

    test('filters by category and keeps unknown kinds under all', () {
      final order = _notification(id: '1', kind: 'order');
      final offer = _notification(id: '2', kind: 'offer');
      final unknown = _notification(id: '3', kind: 'unknown');

      expect(
          filterNotifications([order, offer, unknown], NotificationFilter.all),
          hasLength(3));
      expect(
        filterNotifications([order, offer, unknown], NotificationFilter.orders),
        [order],
      );
      expect(
        filterNotifications([order, offer, unknown], NotificationFilter.offers),
        [offer],
      );
    });

    test('buckets timestamps into today, yesterday, week and older', () {
      final now = DateTime(2026, 5, 20, 12);
      expect(
        dateGroupOf(DateTime(2026, 5, 20, 8).toIso8601String(), now: now),
        NotificationDateGroup.today,
      );
      expect(
        dateGroupOf(DateTime(2026, 5, 19, 23).toIso8601String(), now: now),
        NotificationDateGroup.yesterday,
      );
      expect(
        dateGroupOf(DateTime(2026, 5, 16).toIso8601String(), now: now),
        NotificationDateGroup.thisWeek,
      );
      expect(
        dateGroupOf(DateTime(2026, 5, 1).toIso8601String(), now: now),
        NotificationDateGroup.older,
      );
    });

    test('groups items in design order and drops empty buckets', () {
      final now = DateTime(2026, 5, 20, 12);
      final groups = groupNotifications(
        [
          _notification(id: 'old', createdAt: DateTime(2026, 5, 1)),
          _notification(id: 'today', createdAt: DateTime(2026, 5, 20, 9)),
          _notification(
            id: 'yesterday',
            createdAt: DateTime(2026, 5, 19, 9),
            readAt: '2026-05-19T10:00:00Z',
          ),
        ],
        now: now,
      );

      expect(groups.map((group) => group.group), [
        NotificationDateGroup.today,
        NotificationDateGroup.yesterday,
        NotificationDateGroup.older,
      ]);
      expect(groups.first.items.single.id, 'today');
      expect(groups.first.unreadCount, 1);
      expect(groups[1].unreadCount, 0);
    });

    test('detects order payload and terminal statuses', () {
      final active = _notification(
        data: {'orderId': 'ord_1', 'status': 'confirmed'},
      );
      final cancelled = _notification(
        data: {'orderId': 'ord_2', 'status': 'cancelled'},
      );
      final plain = _notification();

      expect(hasOrder(active), isTrue);
      expect(isOrderActive(active), isTrue);
      expect(isOrderActive(cancelled), isFalse);
      expect(hasOrder(plain), isFalse);
    });
  });

  group('NotificationsHeader', () {
    testWidgets('runs mark all, settings and account actions', (tester) async {
      var marked = 0;
      var settings = 0;
      var account = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: NotificationsHeader(
              unreadCount: 3,
              onBack: () {},
              onMarkAllRead: () => marked++,
              onOpenSettings: () => settings++,
              onOpenAccount: () => account++,
            ),
          ),
        ),
      );

      expect(find.text(_l10n.notifications), findsOneWidget);
      await tester.tap(find.byIcon(Icons.done_all));
      await tester.tap(find.byIcon(Icons.tune));
      await tester.tap(find.byIcon(Icons.person));
      expect(marked, 1);
      expect(settings, 1);
      expect(account, 1);
    });

    testWidgets('disables mark all when there is nothing unread',
        (tester) async {
      var marked = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: NotificationsHeader(
              unreadCount: 0,
              onBack: () {},
              onMarkAllRead: () => marked++,
              onOpenSettings: () {},
              onOpenAccount: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.done_all));
      expect(marked, 0);
    });
  });

  group('NotificationFilterBar', () {
    testWidgets('shows chip counts and reports selection', (tester) async {
      tester.view.physicalSize = const Size(430, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      NotificationFilter? selected;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: NotificationFilterBar(
              selected: NotificationFilter.all,
              counts: const {
                NotificationFilter.all: 8,
                NotificationFilter.orders: 3,
                NotificationFilter.offers: 3,
                NotificationFilter.account: 2,
              },
              unreadCount: 3,
              onSelected: (filter) => selected = filter,
              onMarkAllRead: () {},
            ),
          ),
        ),
      );

      expect(find.text(_l10n.notificationsAllFilter), findsOneWidget);
      expect(find.text(_l10n.notificationsOrdersFilter), findsOneWidget);
      expect(find.text(_l10n.notificationsOffersFilter), findsOneWidget);
      expect(find.text(_l10n.markAllReadAction), findsOneWidget);

      await tester.tap(find.text(_l10n.notificationsOrdersFilter));
      expect(selected, NotificationFilter.orders);

      await tester.ensureVisible(
        find.text(_l10n.notificationsAccountFilter),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.notificationsAccountFilter));
      expect(selected, NotificationFilter.account);
    });
  });

  group('NotificationGroupHeader', () {
    testWidgets('shows a new pill or the read count', (tester) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: Column(
              children: [
                NotificationGroupHeader(
                  group: NotificationDateGroup.today,
                  unreadCount: 2,
                  count: 4,
                ),
                NotificationGroupHeader(
                  group: NotificationDateGroup.yesterday,
                  unreadCount: 0,
                  count: 2,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text(_l10n.notificationsGroupToday), findsOneWidget);
      expect(find.text(_l10n.newNotificationsCount(2)), findsOneWidget);
      expect(find.text(_l10n.notificationCount(2)), findsOneWidget);
    });
  });

  group('NotificationCard', () {
    testWidgets('renders real content and opens the order', (tester) async {
      var opened = 0;
      var marked = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: NotificationCard(
              item: _notification(
                data: {'orderId': 'ord_1', 'status': 'confirmed'},
              ),
              arabic: true,
              onOpen: () => opened++,
              onMarkRead: () => marked++,
            ),
          ),
        ),
      );

      expect(find.text('تم استلام طلبك'), findsOneWidget);
      expect(find.text('طلبك قيد المراجعة.'), findsOneWidget);
      expect(find.text(_l10n.newBadge), findsOneWidget);
      expect(find.text(_l10n.trackOrderFull), findsOneWidget);

      await tester.tap(find.text(_l10n.trackOrderFull));
      expect(opened, 1);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.notificationMarkRead));
      await tester.pumpAndSettle();
      expect(marked, 1);
    });

    testWidgets('terminal orders show the view order action', (tester) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: NotificationCard(
              item: _notification(
                titleAr: 'تم إلغاء طلبك',
                data: {'orderId': 'ord_2', 'status': 'cancelled'},
                readAt: '2026-01-01T00:00:00Z',
              ),
              arabic: true,
              onOpen: () {},
              onMarkRead: () {},
            ),
          ),
        ),
      );

      expect(find.text(_l10n.viewOrder), findsOneWidget);
      expect(find.text(_l10n.newBadge), findsNothing);
    });
  });

  group('NotificationSettingsCard', () {
    testWidgets('toggles the preference and opens settings', (tester) async {
      bool? changed;
      var managed = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: NotificationSettingsCard(
              enabled: true,
              onChanged: (value) => changed = value,
              onManage: () => managed++,
              versionLabel: 'الإصدار 1.0.0',
            ),
          ),
        ),
      );

      expect(find.text(_l10n.notificationsSettingsTitle), findsOneWidget);
      expect(find.text('الإصدار 1.0.0'), findsOneWidget);

      await tester.tap(find.byType(AnimatedContainer));
      expect(changed, isFalse);

      await tester.tap(find.text(_l10n.manageNotificationSettings));
      expect(managed, 1);
    });
  });

  group('NotificationEmptyState', () {
    testWidgets('renders copy and runs the action', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: NotificationEmptyState(
              title: _l10n.notificationsEmptyTitle,
              message: _l10n.notificationsEmptyMessage,
              actionLabel: _l10n.backToAllNotifications,
              onAction: () => tapped++,
            ),
          ),
        ),
      );

      expect(find.text(_l10n.notificationsEmptyTitle), findsOneWidget);
      await tester.tap(find.text(_l10n.backToAllNotifications));
      expect(tapped, 1);
    });
  });

  group('NotificationsScreen', () {
    testWidgets('renders live groups, filters and settings card',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = _FakeNotifications(
        _page([
          _notification(
            id: '1',
            data: {'orderId': 'ord_1', 'status': 'confirmed'},
          ),
          _notification(
            id: '2',
            kind: 'offer',
            titleAr: 'عرض حصري اليوم',
            bodyAr: 'خصم على وجبتك القادمة.',
            createdAt: _now.subtract(const Duration(days: 1)),
            readAt: '2026-01-01T00:00:00Z',
          ),
        ]),
      );

      await tester.pumpWidget(
        testApp(
          const NotificationsScreen(),
          overrides: [
            sessionProvider.overrideWith(() => _SignedInSession(_profile)),
            notificationsProvider.overrideWith(() => controller),
            tokenStoreProvider.overrideWithValue(_FakeTokenStore()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تم استلام طلبك'), findsOneWidget);
      expect(find.text('عرض حصري اليوم'), findsOneWidget);
      expect(find.text(_l10n.notificationsGroupToday), findsOneWidget);
      expect(find.text(_l10n.notificationsGroupYesterday), findsOneWidget);
      expect(find.text(_l10n.trackOrderFull), findsOneWidget);
      expect(find.text(_l10n.notificationsSettingsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mark all read calls the controller', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = _FakeNotifications(
        _page([
          _notification(data: {'orderId': 'ord_1'})
        ]),
      );

      await tester.pumpWidget(
        testApp(
          const NotificationsScreen(),
          overrides: [
            sessionProvider.overrideWith(() => _SignedInSession(_profile)),
            notificationsProvider.overrideWith(() => controller),
            tokenStoreProvider.overrideWithValue(_FakeTokenStore()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.done_all).first);
      await tester.pumpAndSettle();
      expect(controller.markAllCalls, 1);
    });

    testWidgets('guest sees the sign-in empty state', (tester) async {
      await tester.pumpWidget(
        testApp(
          const NotificationsScreen(),
          overrides: [sessionProvider.overrideWith(_GuestSession.new)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_l10n.signIn), findsOneWidget);
      expect(find.text(_l10n.noNotifications), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

const _profile = CustomerProfile(
  id: 'cus_1',
  name: 'أحمد علي',
  initials: 'أع',
  phone: '+966500000000',
  email: 'ahmed@example.com',
  language: 'ar',
  avatarUrl: null,
  status: 'active',
  memberSince: '2024-01-01',
  orderCount: 12,
  defaultAddress: null,
);

class _GuestSession extends SessionController {
  @override
  Future<CustomerProfile?> build() async => null;
}

class _SignedInSession extends SessionController {
  _SignedInSession(this.profile);

  final CustomerProfile profile;

  @override
  Future<CustomerProfile?> build() async => profile;
}

class _FakeNotifications extends NotificationsController {
  _FakeNotifications(this.page);

  NotificationPage page;
  int markAllCalls = 0;

  @override
  Future<NotificationPage> build() async => page;

  @override
  Future<void> markAllRead() async {
    markAllCalls++;
    page = NotificationPage(
      items: page.items
          .map(
            (item) => CustomerNotification(
              id: item.id,
              kind: item.kind,
              titleAr: item.titleAr,
              titleEn: item.titleEn,
              bodyAr: item.bodyAr,
              bodyEn: item.bodyEn,
              data: item.data,
              readAt: _now.toIso8601String(),
              createdAt: item.createdAt,
            ),
          )
          .toList(),
      page: page.page,
      pageSize: page.pageSize,
      total: page.total,
      hasMore: page.hasMore,
      unreadCount: 0,
    );
    state = AsyncValue.data(page);
  }
}

class _FakeTokenStore extends TokenStore {
  @override
  bool get cachedNotificationsEnabled => true;

  @override
  Future<bool?> readNotificationsEnabled() async => true;

  @override
  Future<void> writeNotificationsEnabled(bool value) async {}
}
