import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/catalog.dart';
import '../data/models/search.dart';
import 'address_controller.dart';
import 'providers.dart';

class RestaurantListState {
  const RestaurantListState({
    required this.items,
    required this.query,
    required this.hasMore,
    required this.total,
    required this.availableSorts,
    this.loadingMore = false,
  });

  final List<CatalogRestaurant> items;
  final RestaurantQuery query;
  final bool hasMore;
  final int total;
  final List<String> availableSorts;
  final bool loadingMore;

  RestaurantListState copyWith({
    List<CatalogRestaurant>? items,
    RestaurantQuery? query,
    bool? hasMore,
    int? total,
    List<String>? availableSorts,
    bool? loadingMore,
  }) {
    return RestaurantListState(
      items: items ?? this.items,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      availableSorts: availableSorts ?? this.availableSorts,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

final restaurantsProvider =
    AsyncNotifierProvider.family<RestaurantsController, RestaurantListState, String?>(
  RestaurantsController.new,
);

class RestaurantsController extends FamilyAsyncNotifier<RestaurantListState, String?> {
  late RestaurantQuery _query =
      RestaurantQuery(categoryIds: arg == null ? const [] : [arg!]);

  @override
  Future<RestaurantListState> build(String? categoryId) async {
    ref.watch(selectedAddressProvider);
    final query = _query;
    final page = await _fetch(query);
    return RestaurantListState(
      items: page.items,
      query: query,
      hasMore: page.hasMore,
      total: page.total,
      availableSorts: page.availableSorts,
    );
  }

  RestaurantQuery _withAddress(RestaurantQuery query) {
    final address = ref.read(selectedAddressProvider);
    return query.copyWith(
      addressId: address?.id,
      lat: address?.lat,
      lng: address?.lng,
      clearAddress: address == null,
    );
  }

  Future<CatalogRestaurantList> _fetch(RestaurantQuery query) {
    return ref.read(catalogRepositoryProvider).restaurants(_withAddress(query));
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous != null) state = AsyncValue.data(previous);
    try {
      final page = await _fetch(_query);
      state = AsyncValue.data(
        RestaurantListState(
          items: page.items,
          query: _query,
          hasMore: page.hasMore,
          total: page.total,
          availableSorts: page.availableSorts,
        ),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> setSort(String sort) async {
    if (sort == _query.sort) return;
    _query = _query.copyWith(sort: sort, page: 1);
    await _reload();
  }

  Future<void> applyFilters(RestaurantQuery filters) async {
    _query = filters.copyWith(page: 1, sort: _query.sort);
    await _reload();
  }

  Future<void> clearFilters() async {
    _query = RestaurantQuery(sort: _query.sort);
    await _reload();
  }

  Future<void> _reload() async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(previous.copyWith(loadingMore: false));
    } else {
      state = const AsyncValue.loading();
    }
    try {
      final page = await _fetch(_query);
      state = AsyncValue.data(
        RestaurantListState(
          items: page.items,
          query: _query,
          hasMore: page.hasMore,
          total: page.total,
          availableSorts: page.availableSorts,
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
      final next = await _fetch(_query.copyWith(page: current.query.page + 1));
      _query = _query.copyWith(page: current.query.page + 1);
      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...next.items],
          query: _query,
          hasMore: next.hasMore,
          total: next.total,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}
