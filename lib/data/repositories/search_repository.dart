import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/search.dart';

class SearchRepository {
  SearchRepository(this._api);

  final ApiClient _api;

  Future<SearchConfig> config() async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/search/config',
      cacheFor: const Duration(minutes: 5),
    );
    return SearchConfig.fromJson(data);
  }

  Future<SearchSuggestions> suggest(
    String query, {
    String? addressId,
    double? lat,
    double? lng,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/search/suggest',
      query: {
        'q': query,
        'addressId': addressId,
        'lat': lat,
        'lng': lng,
        'limit': limit,
      },
      cancelToken: cancelToken,
    );
    return SearchSuggestions.fromJson(data);
  }

  Future<SearchResults> results(
    String query, {
    String? addressId,
    double? lat,
    double? lng,
    int page = 1,
    int? pageSize,
    CancelToken? cancelToken,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/search/results',
      query: {
        'q': query,
        'addressId': addressId,
        'lat': lat,
        'lng': lng,
        'page': page,
        'pageSize': pageSize,
      },
      cancelToken: cancelToken,
    );
    return SearchResults.fromJson(data);
  }

  Future<List<SearchHistoryItem>> history() async {
    final data = await _api.get<List<dynamic>>('/api/customer/search/history');
    return data.map((e) => SearchHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clearHistory() => _api.delete<dynamic>('/api/customer/search/history');

  Future<void> deleteHistoryItem(String id) =>
      _api.delete<dynamic>('/api/customer/search/history/$id');

  Future<void> recordClick({required String targetType, required String targetId}) async {
    await _api.post<dynamic>(
      '/api/customer/search/clicks',
      body: {'targetType': targetType, 'targetId': targetId},
    );
  }
}
