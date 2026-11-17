import '../api/api_client.dart';
import '../models/account.dart';

class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  Future<WalletSummary> wallet() async {
    final data = await _api.get<Map<String, dynamic>>('/api/customer/wallet');
    return WalletSummary.fromJson(data);
  }

  Future<LoyaltySummary> loyalty() async {
    final data = await _api.get<Map<String, dynamic>>('/api/customer/loyalty');
    return LoyaltySummary.fromJson(data);
  }

  Future<NotificationPage> notifications({
    int page = 1,
    int pageSize = 30,
    bool? unreadOnly,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/notifications',
      query: {'page': page, 'pageSize': pageSize, 'unreadOnly': unreadOnly},
    );
    return NotificationPage.fromJson(data);
  }

  Future<CustomerNotification> markRead(String id) async {
    final data = await _api
        .post<Map<String, dynamic>>('/api/customer/notifications/$id/read');
    return CustomerNotification.fromJson(data);
  }

  Future<void> markAllRead() =>
      _api.post<dynamic>('/api/customer/notifications/read-all');

  /// Registers the current FCM device token with the backend. The token is
  /// reassigned to the signed-in customer when the same device switches
  /// accounts.
  Future<void> registerDevice({
    required String token,
    required String platform,
    String? appVersion,
  }) async {
    await _api.post<dynamic>(
      '/api/customer/devices',
      body: {
        'token': token,
        'platform': platform,
        if (appVersion != null && appVersion.isNotEmpty)
          'appVersion': appVersion,
      },
    );
  }

  Future<void> unregisterDevice(String token) async {
    await _api.delete<dynamic>(
      '/api/customer/devices',
      body: {'token': token},
    );
  }

  Future<List<SupportTicket>> tickets() async {
    final data = await _api.get<List<dynamic>>('/api/customer/tickets');
    return data
        .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupportTicket> ticket(String id) async {
    final data =
        await _api.get<Map<String, dynamic>>('/api/customer/tickets/$id');
    return SupportTicket.fromJson(data);
  }

  Future<SupportTicket> createTicket({
    String? orderId,
    String category = 'general',
    required String subject,
    required String description,
    String priority = 'normal',
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/tickets',
      body: {
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
        'category': category,
        'subject': subject,
        'description': description,
        'priority': priority,
      },
    );
    return SupportTicket.fromJson(data);
  }

  Future<SupportTicket> replyTicket(String id, String body) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/tickets/$id/messages',
      body: {'body': body},
    );
    return SupportTicket.fromJson(data);
  }

  Future<RatingResult> rateOrder({
    required String orderId,
    int? restaurantStars,
    String? restaurantComment,
    int? driverStars,
    String? driverComment,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/ratings',
      body: {
        'orderId': orderId,
        if (restaurantStars != null)
          'restaurant': {
            'stars': restaurantStars,
            if (restaurantComment != null && restaurantComment.isNotEmpty)
              'comment': restaurantComment,
          },
        if (driverStars != null)
          'driver': {
            'stars': driverStars,
            if (driverComment != null && driverComment.isNotEmpty)
              'comment': driverComment,
          },
      },
    );
    return RatingResult.fromJson(data);
  }
}
