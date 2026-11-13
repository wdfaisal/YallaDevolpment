import '../api/api_client.dart';
import '../models/orders.dart';

class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<OrderList> list({
    int page = 1,
    int pageSize = 20,
    String? status,
    bool? active,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/orders',
      query: {
        'page': page,
        'pageSize': pageSize,
        'status': status,
        'active': active,
      },
    );
    return OrderList.fromJson(data);
  }

  Future<OrderDetail> get(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/api/customer/orders/$id');
    return OrderDetail.fromJson(data);
  }

  Future<OrderDetail> cancel(String id, {String? reason}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/orders/$id/cancel',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return OrderDetail.fromJson(data);
  }
}
