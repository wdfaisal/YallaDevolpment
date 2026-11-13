import '../api/api_client.dart';
import '../models/customer.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<OtpChallenge> requestOtp({
    required String phone,
    String purpose = 'login',
    String language = 'ar',
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/auth/otp/request',
      body: {'phone': phone, 'purpose': purpose, 'language': language},
    );
    return OtpChallenge.fromJson(data);
  }

  Future<CustomerSession> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String? email,
    String language = 'ar',
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/auth/otp/verify',
      body: {
        'phone': phone,
        'code': code,
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        'language': language,
      },
    );
    return CustomerSession.fromJson(data);
  }

  Future<CustomerProfile> me() async {
    final data = await _api.get<Map<String, dynamic>>('/api/customer/auth/me');
    return CustomerProfile.fromJson(data);
  }

  Future<CustomerProfile> updateProfile({
    String? name,
    String? email,
    String? language,
    String? avatarUrl,
    bool clearEmail = false,
    bool clearAvatar = false,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/api/customer/auth/profile',
      body: {
        if (name != null) 'name': name,
        if (clearEmail) 'email': null else if (email != null) 'email': email,
        if (language != null) 'language': language,
        if (clearAvatar) 'avatarUrl': null else if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return CustomerProfile.fromJson(data);
  }

  Future<void> logout() => _api.post<dynamic>('/api/customer/auth/logout');
}
