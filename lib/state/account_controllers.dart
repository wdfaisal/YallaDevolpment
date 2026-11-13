import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account.dart';
import 'providers.dart';
import 'session_controller.dart';

final walletProvider =
    AsyncNotifierProvider<WalletController, WalletSummary>(WalletController.new);

class WalletController extends AsyncNotifier<WalletSummary> {
  @override
  Future<WalletSummary> build() async {
    ref.watch(personalEpochProvider);
    if (ref.watch(sessionProvider).valueOrNull == null) {
      return const WalletSummary(availableMinor: 0, heldMinor: 0, currency: 'SAR', entries: []);
    }
    return ref.read(accountRepositoryProvider).wallet();
  }

  Future<void> refresh() async {
    state = AsyncValue.data(
      state.valueOrNull ??
          const WalletSummary(availableMinor: 0, heldMinor: 0, currency: 'SAR', entries: []),
    );
    try {
      state = AsyncValue.data(await ref.read(accountRepositoryProvider).wallet());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final loyaltyProvider =
    AsyncNotifierProvider<LoyaltyController, LoyaltySummary>(LoyaltyController.new);

class LoyaltyController extends AsyncNotifier<LoyaltySummary> {
  @override
  Future<LoyaltySummary> build() async {
    ref.watch(personalEpochProvider);
    if (ref.watch(sessionProvider).valueOrNull == null) {
      return const LoyaltySummary(points: 0, entries: []);
    }
    return ref.read(accountRepositoryProvider).loyalty();
  }
}

const _emptyNotifications = NotificationPage(
  items: [],
  page: 1,
  pageSize: 30,
  total: 0,
  hasMore: false,
  unreadCount: 0,
);

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, NotificationPage>(
  NotificationsController.new,
);

/// Unread badge for the account/home header.
final unreadNotificationsProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).valueOrNull?.unreadCount ?? 0;
});

class NotificationsController extends AsyncNotifier<NotificationPage> {
  @override
  Future<NotificationPage> build() async {
    ref.watch(personalEpochProvider);
    if (ref.watch(sessionProvider).valueOrNull == null) return _emptyNotifications;
    return ref.read(accountRepositoryProvider).notifications();
  }

  Future<void> refresh() async {
    if (ref.read(sessionProvider).valueOrNull == null) {
      state = const AsyncValue.data(_emptyNotifications);
      return;
    }
    state = AsyncValue.data(state.valueOrNull ?? _emptyNotifications);
    try {
      state = AsyncValue.data(await ref.read(accountRepositoryProvider).notifications());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    try {
      final next = await ref.read(accountRepositoryProvider).notifications(
            page: current.page + 1,
            pageSize: current.pageSize,
          );
      state = AsyncValue.data(
        NotificationPage(
          items: [...current.items, ...next.items],
          page: next.page,
          pageSize: next.pageSize,
          total: next.total,
          hasMore: next.hasMore,
          unreadCount: next.unreadCount,
        ),
      );
    } catch (_) {
      // Keep the existing page on pagination failure.
    }
  }

  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = await ref.read(accountRepositoryProvider).markRead(id);
    state = AsyncValue.data(
      NotificationPage(
        items: current.items.map((n) => n.id == id ? updated : n).toList(growable: false),
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
        hasMore: current.hasMore,
        unreadCount: (current.unreadCount - 1).clamp(0, current.unreadCount),
      ),
    );
  }

  Future<void> markAllRead() async {
    await ref.read(accountRepositoryProvider).markAllRead();
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      NotificationPage(
        items: current.items
            .map(
              (n) => n.isUnread
                  ? CustomerNotification(
                      id: n.id,
                      kind: n.kind,
                      titleAr: n.titleAr,
                      titleEn: n.titleEn,
                      bodyAr: n.bodyAr,
                      bodyEn: n.bodyEn,
                      data: n.data,
                      readAt: DateTime.now().toIso8601String(),
                      createdAt: n.createdAt,
                    )
                  : n,
            )
            .toList(growable: false),
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
        hasMore: current.hasMore,
        unreadCount: 0,
      ),
    );
  }
}

final ticketsProvider =
    AsyncNotifierProvider<TicketsController, List<SupportTicket>>(TicketsController.new);

class TicketsController extends AsyncNotifier<List<SupportTicket>> {
  @override
  Future<List<SupportTicket>> build() async {
    ref.watch(personalEpochProvider);
    if (ref.watch(sessionProvider).valueOrNull == null) return const [];
    return ref.read(accountRepositoryProvider).tickets();
  }

  Future<void> refresh() async {
    state = AsyncValue.data(state.valueOrNull ?? const []);
    try {
      state = AsyncValue.data(await ref.read(accountRepositoryProvider).tickets());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<SupportTicket> create({
    String? orderId,
    String category = 'general',
    required String subject,
    required String description,
    String priority = 'normal',
  }) async {
    final ticket = await ref.read(accountRepositoryProvider).createTicket(
          orderId: orderId,
          category: category,
          subject: subject,
          description: description,
          priority: priority,
        );
    await refresh();
    return ticket;
  }
}

final ticketDetailProvider =
    AsyncNotifierProvider.family<TicketDetailController, SupportTicket, String>(
  TicketDetailController.new,
);

class TicketDetailController extends FamilyAsyncNotifier<SupportTicket, String> {
  @override
  Future<SupportTicket> build(String id) {
    return ref.read(accountRepositoryProvider).ticket(id);
  }

  Future<void> reply(String body) async {
    final updated = await ref.read(accountRepositoryProvider).replyTicket(arg, body);
    state = AsyncValue.data(updated);
    ref.invalidate(ticketsProvider);
  }
}
