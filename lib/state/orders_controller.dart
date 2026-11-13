import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/orders.dart';
import 'providers.dart';
import 'session_controller.dart';

enum OrdersTab { active, past }

class OrdersState {
  const OrdersState({
    required this.items,
    required this.hasMore,
    required this.page,
    required this.total,
    this.loadingMore = false,
  });

  static const empty = OrdersState(items: [], hasMore: false, page: 1, total: 0);

  final List<OrderSummary> items;
  final bool hasMore;
  final int page;
  final int total;
  final bool loadingMore;

  OrdersState copyWith({
    List<OrderSummary>? items,
    bool? hasMore,
    int? page,
    int? total,
    bool? loadingMore,
  }) {
    return OrdersState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

final ordersProvider = AsyncNotifierProvider.family<OrdersController, OrdersState, OrdersTab>(
  OrdersController.new,
);

class OrdersController extends FamilyAsyncNotifier<OrdersState, OrdersTab> {
  @override
  Future<OrdersState> build(OrdersTab tab) async {
    ref.watch(personalEpochProvider);
    if (ref.watch(sessionProvider).valueOrNull == null) return OrdersState.empty;
    final page = await ref.read(ordersRepositoryProvider).list(
          page: 1,
          active: tab == OrdersTab.active,
        );
    return OrdersState(
      items: page.items,
      hasMore: page.hasMore,
      page: page.page,
      total: page.total,
    );
  }

  Future<void> refresh() async {
    if (ref.read(sessionProvider).valueOrNull == null) {
      state = const AsyncValue.data(OrdersState.empty);
      return;
    }
    final previous = state.valueOrNull;
    if (previous != null) state = AsyncValue.data(previous);
    try {
      final page = await ref.read(ordersRepositoryProvider).list(
            page: 1,
            active: arg == OrdersTab.active,
          );
      state = AsyncValue.data(
        OrdersState(
          items: page.items,
          hasMore: page.hasMore,
          page: page.page,
          total: page.total,
        ),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(ordersRepositoryProvider).list(
            page: current.page + 1,
            active: arg == OrdersTab.active,
          );
      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          page: page.page,
          total: page.total,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}

final orderDetailProvider =
    AsyncNotifierProvider.family<OrderDetailController, OrderDetail, String>(
  OrderDetailController.new,
);

class OrderDetailController extends FamilyAsyncNotifier<OrderDetail, String> {
  @override
  Future<OrderDetail> build(String id) async {
    return ref.read(ordersRepositoryProvider).get(id);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous != null) state = AsyncValue.data(previous);
    try {
      state = AsyncValue.data(await ref.read(ordersRepositoryProvider).get(arg));
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> cancel({String? reason}) async {
    final updated = await ref.read(ordersRepositoryProvider).cancel(arg, reason: reason);
    state = AsyncValue.data(updated);
    ref.invalidate(ordersProvider);
  }
}
