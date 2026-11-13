import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/catalog.dart';
import 'address_controller.dart';
import 'providers.dart';

/// Restaurant details are cached per id and kept alive for the session so
/// returning to a restaurant is instant; [refresh] re-validates prices.
final restaurantDetailProvider = AsyncNotifierProvider.family<RestaurantDetailController,
    CatalogRestaurantDetail, String>(RestaurantDetailController.new);

class RestaurantDetailController extends FamilyAsyncNotifier<CatalogRestaurantDetail, String> {
  @override
  Future<CatalogRestaurantDetail> build(String id) async {
    final address = ref.watch(selectedAddressProvider);
    return ref.read(catalogRepositoryProvider).restaurant(
          id,
          addressId: address?.id,
          lat: address?.lat,
          lng: address?.lng,
        );
  }

  Future<void> refresh() async {
    final address = ref.read(selectedAddressProvider);
    final previous = state.valueOrNull;
    if (previous != null) state = AsyncValue.data(previous);
    try {
      state = AsyncValue.data(
        await ref.read(catalogRepositoryProvider).restaurant(
              arg,
              addressId: address?.id,
              lat: address?.lat,
              lng: address?.lng,
            ),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Updates the cached favorite flag after a toggle without refetching.
  void setFavorite(bool value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      CatalogRestaurantDetail(
        restaurant: current.restaurant,
        address: current.address,
        phone: current.phone,
        opensAt: current.opensAt,
        closesAt: current.closesAt,
        deliveryFeeMinor: current.deliveryFeeMinor,
        minOrderMinor: current.minOrderMinor,
        menu: current.menu,
        offers: current.offers,
        isFavorite: value,
      ),
    );
  }
}
