import '../api/api_client.dart';
import '../models/catalog.dart';
import '../models/search.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<CatalogHome> home({String? addressId, double? lat, double? lng}) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/catalog/home',
      query: {'addressId': addressId, 'lat': lat, 'lng': lng},
      cacheFor: const Duration(seconds: 30),
    );
    return CatalogHome.fromJson(data);
  }

  Future<CatalogRestaurantList> restaurants(RestaurantQuery query) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/catalog/restaurants',
      query: query.toQuery(),
      cacheFor: const Duration(seconds: 20),
    );
    return CatalogRestaurantList.fromJson(data);
  }

  Future<CatalogRestaurantDetail> restaurant(
    String id, {
    String? addressId,
    double? lat,
    double? lng,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/catalog/restaurants/$id',
      query: {'addressId': addressId, 'lat': lat, 'lng': lng},
      cacheFor: const Duration(seconds: 20),
    );
    return CatalogRestaurantDetail.fromJson(data);
  }

  Future<CatalogMenuItem> menuItem(
    String id, {
    String? addressId,
    double? lat,
    double? lng,
  }) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/catalog/menu-items/$id',
      query: {'addressId': addressId, 'lat': lat, 'lng': lng},
      cacheFor: const Duration(seconds: 20),
    );
    return CatalogMenuItem.fromJson(data);
  }

  Future<List<CatalogCategory>> categories() async {
    final data = await _api.get<List<dynamic>>(
      '/api/customer/catalog/categories',
      cacheFor: const Duration(minutes: 2),
    );
    return data.map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CatalogOffer>> offers({String? addressId, double? lat, double? lng}) async {
    final data = await _api.get<List<dynamic>>(
      '/api/customer/catalog/offers',
      query: {'addressId': addressId, 'lat': lat, 'lng': lng},
      cacheFor: const Duration(seconds: 30),
    );
    return data.map((e) => CatalogOffer.fromJson(e as Map<String, dynamic>)).toList();
  }
}
