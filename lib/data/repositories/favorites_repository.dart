import '../api/api_client.dart';
import '../models/account.dart';

class FavoritesRepository {
  FavoritesRepository(this._api);

  final ApiClient _api;

  Future<List<FavoriteRecord>> list() async {
    final data = await _api.get<List<dynamic>>('/api/customer/favorites');
    return data.map((e) => FavoriteRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FavoriteRecord> add({required String targetType, required String targetId}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/favorites',
      body: {'targetType': targetType, 'targetId': targetId},
    );
    return FavoriteRecord.fromJson(data);
  }

  Future<void> remove({required String targetType, required String targetId}) =>
      _api.delete<dynamic>('/api/customer/favorites/$targetType/$targetId');
}
