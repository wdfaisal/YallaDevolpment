import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/catalog.dart';
import 'address_controller.dart';
import 'providers.dart';

/// Home payload for the selected address. Keeps the previous payload visible
/// while a new address loads, so switching addresses never flashes empty.
final homeProvider = AsyncNotifierProvider<HomeController, CatalogHome>(HomeController.new);

class HomeController extends AsyncNotifier<CatalogHome> {
  @override
  Future<CatalogHome> build() async {
    final address = ref.watch(selectedAddressProvider);
    return ref.read(catalogRepositoryProvider).home(addressId: address?.id);
  }

  Future<void> refresh() async {
    final address = ref.read(selectedAddressProvider);
    final previous = state.valueOrNull;
    if (previous != null) state = AsyncValue.data(previous);
    try {
      state = AsyncValue.data(
        await ref.read(catalogRepositoryProvider).home(addressId: address?.id),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
