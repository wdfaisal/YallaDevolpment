import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cart.dart';
import 'providers.dart';
import 'session_controller.dart';

const _emptyCart = CartResponse(
  cartId: null,
  restaurantId: null,
  restaurantName: null,
  lines: [],
  itemCount: 0,
  updatedAt: null,
  quote: null,
);

final cartProvider = AsyncNotifierProvider<CartController, CartResponse>(CartController.new);

/// Badge count for the shell header.
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).valueOrNull?.itemCount ?? 0;
});

class CartController extends AsyncNotifier<CartResponse> {
  @override
  Future<CartResponse> build() async {
    ref.watch(personalEpochProvider);
    final signedIn = ref.watch(sessionProvider).valueOrNull != null;
    if (!signedIn) return _emptyCart;
    return ref.read(cartRepositoryProvider).get();
  }

  Future<void> refresh() async {
    if (ref.read(sessionProvider).valueOrNull == null) {
      state = const AsyncValue.data(_emptyCart);
      return;
    }
    final previous = state.valueOrNull;
    if (previous != null) state = AsyncValue.data(previous);
    try {
      state = AsyncValue.data(await ref.read(cartRepositoryProvider).get());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addItem({
    required String menuItemId,
    required int quantity,
    List<String> optionIds = const [],
    String notes = '',
  }) async {
    final updated = await ref.read(cartRepositoryProvider).addItem(
          menuItemId: menuItemId,
          quantity: quantity,
          optionIds: optionIds,
          notes: notes,
        );
    state = AsyncValue.data(updated);
  }

  Future<void> updateItem(
    String lineId, {
    int? quantity,
    List<String>? optionIds,
    String? notes,
  }) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        CartResponse(
          cartId: current.cartId,
          restaurantId: current.restaurantId,
          restaurantName: current.restaurantName,
          lines: current.lines,
          itemCount: current.itemCount,
          updatedAt: current.updatedAt,
          quote: current.quote,
        ),
      );
    }
    final updated = await ref.read(cartRepositoryProvider).updateItem(
          lineId,
          quantity: quantity,
          optionIds: optionIds,
          notes: notes,
        );
    state = AsyncValue.data(updated);
  }

  Future<void> changeQuantity(CartLine line, int quantity) async {
    if (quantity <= 0) {
      await removeItem(line.id);
    } else {
      await updateItem(line.id, quantity: quantity);
    }
  }

  Future<void> removeItem(String lineId) async {
    final updated = await ref.read(cartRepositoryProvider).removeItem(lineId);
    state = AsyncValue.data(updated);
  }

  Future<void> clear() async {
    final updated = await ref.read(cartRepositoryProvider).clear();
    state = AsyncValue.data(updated);
  }

  /// Recomputes the authoritative quote (fees, tax, discounts, payment
  /// methods) without mutating the cart.
  Future<CartQuote> quote(QuoteRequest request) async {
    final quote = await ref.read(cartRepositoryProvider).quote(request);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        CartResponse(
          cartId: current.cartId,
          restaurantId: current.restaurantId,
          restaurantName: current.restaurantName,
          lines: current.lines,
          itemCount: current.itemCount,
          updatedAt: current.updatedAt,
          quote: quote,
        ),
      );
    }
    return quote;
  }

  Future<CheckoutResult> checkout(CheckoutRequest request) async {
    final result = await ref.read(cartRepositoryProvider).checkout(request);
    state = const AsyncValue.data(_emptyCart);
    return result;
  }
}
