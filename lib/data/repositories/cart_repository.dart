import '../api/api_client.dart';
import '../models/cart.dart';

class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  Future<CartResponse> get() async {
    final data = await _api.get<Map<String, dynamic>>('/api/customer/cart');
    return CartResponse.fromJson(data);
  }

  Future<CartResponse> addItem({
    required String menuItemId,
    required int quantity,
    List<String> optionIds = const [],
    String notes = '',
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/cart/items',
      body: {
        'menuItemId': menuItemId,
        'quantity': quantity,
        if (optionIds.isNotEmpty) 'optionIds': optionIds,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return CartResponse.fromJson(data);
  }

  Future<CartResponse> updateItem(
    String lineId, {
    int? quantity,
    List<String>? optionIds,
    String? notes,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/api/customer/cart/items/$lineId',
      body: {
        if (quantity != null) 'quantity': quantity,
        if (optionIds != null) 'optionIds': optionIds,
        if (notes != null) 'notes': notes,
      },
    );
    return CartResponse.fromJson(data);
  }

  Future<CartResponse> removeItem(String lineId) async {
    final data = await _api.delete<Map<String, dynamic>>('/api/customer/cart/items/$lineId');
    return CartResponse.fromJson(data);
  }

  Future<CartResponse> clear() async {
    final data = await _api.delete<Map<String, dynamic>>('/api/customer/cart');
    return CartResponse.fromJson(data);
  }

  Future<CartQuote> quote(QuoteRequest request) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/cart/quote',
      body: request.toJson(),
    );
    return CartQuote.fromJson(data);
  }

  Future<CheckoutResult> checkout(CheckoutRequest request) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/cart/checkout',
      body: request.toJson(),
    );
    return CheckoutResult.fromJson(data);
  }
}
