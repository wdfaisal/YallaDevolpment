import '../../data/models/account.dart';

/// Categories exposed by the notification filter chips.
enum NotificationCategory { orders, offers, account }

/// Filter chips shown above the notification stream.
enum NotificationFilter { all, orders, offers, account }

/// Date buckets used to group notifications in the stream.
enum NotificationDateGroup { today, yesterday, thisWeek, older }

extension NotificationFilterCategory on NotificationFilter {
  NotificationCategory? get category => switch (this) {
        NotificationFilter.all => null,
        NotificationFilter.orders => NotificationCategory.orders,
        NotificationFilter.offers => NotificationCategory.offers,
        NotificationFilter.account => NotificationCategory.account,
      };
}

/// Maps a backend notification kind to the chip it belongs to. Unknown kinds
/// stay visible under "All" but are not counted in a specific chip.
NotificationCategory? categoryOfKind(String kind) {
  return switch (kind) {
    'order' || 'order_status' || 'delivery' => NotificationCategory.orders,
    'offer' ||
    'promo' ||
    'promotion' ||
    'coupon' ||
    'discount' =>
      NotificationCategory.offers,
    'wallet' ||
    'payment' ||
    'loyalty' ||
    'points' ||
    'account' ||
    'auth' ||
    'security' ||
    'support' ||
    'ticket' =>
      NotificationCategory.account,
    _ => null,
  };
}

bool matchesFilter(CustomerNotification item, NotificationFilter filter) {
  final category = filter.category;
  if (category == null) return true;
  return categoryOfKind(item.kind) == category;
}

List<CustomerNotification> filterNotifications(
  List<CustomerNotification> items,
  NotificationFilter filter,
) {
  if (filter == NotificationFilter.all) return items;
  return items.where((item) => matchesFilter(item, filter)).toList();
}

/// Counts for the filter chips. The "All" count comes from the backend total;
/// category counts are derived from the loaded, real items.
Map<NotificationFilter, int> filterCounts(NotificationPage page) {
  final counts = <NotificationFilter, int>{
    NotificationFilter.all:
        page.total < page.items.length ? page.items.length : page.total,
    NotificationFilter.orders: 0,
    NotificationFilter.offers: 0,
    NotificationFilter.account: 0,
  };
  for (final item in page.items) {
    final category = categoryOfKind(item.kind);
    if (category == null) continue;
    final filter = switch (category) {
      NotificationCategory.orders => NotificationFilter.orders,
      NotificationCategory.offers => NotificationFilter.offers,
      NotificationCategory.account => NotificationFilter.account,
    };
    counts[filter] = (counts[filter] ?? 0) + 1;
  }
  return counts;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Buckets a real ISO timestamp into today / yesterday / this week / older.
NotificationDateGroup dateGroupOf(String iso, {DateTime? now}) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return NotificationDateGroup.older;
  final today = _dateOnly((now ?? DateTime.now()).toLocal());
  final day = _dateOnly(parsed.toLocal());
  final days = today.difference(day).inDays;
  if (days <= 0) return NotificationDateGroup.today;
  if (days == 1) return NotificationDateGroup.yesterday;
  if (days < 7) return NotificationDateGroup.thisWeek;
  return NotificationDateGroup.older;
}

class NotificationGroup {
  const NotificationGroup({required this.group, required this.items});

  final NotificationDateGroup group;
  final List<CustomerNotification> items;

  int get unreadCount => items.where((item) => item.isUnread).length;
}

/// Groups the visible items in the fixed design order, dropping empty buckets.
List<NotificationGroup> groupNotifications(
  List<CustomerNotification> items, {
  DateTime? now,
}) {
  final buckets = <NotificationDateGroup, List<CustomerNotification>>{
    for (final group in NotificationDateGroup.values) group: [],
  };
  for (final item in items) {
    buckets[dateGroupOf(item.createdAt, now: now)]!.add(item);
  }
  return [
    for (final group in NotificationDateGroup.values)
      if (buckets[group]!.isNotEmpty)
        NotificationGroup(group: group, items: buckets[group]!),
  ];
}

/// Order notifications carry the order id in their data payload.
bool hasOrder(CustomerNotification item) {
  final id = item.orderId;
  return id != null && id.isNotEmpty;
}

/// The backend includes the order status in the notification payload.
String? orderStatusOf(CustomerNotification item) {
  final status = item.data?['status'];
  return status is String && status.isNotEmpty ? status : null;
}

/// Terminal orders only get a "View order" action; active ones get tracking.
bool isOrderActive(CustomerNotification item) {
  final status = orderStatusOf(item);
  if (status == null) return false;
  return !const {'delivered', 'cancelled', 'failed_delivery'}.contains(status);
}
