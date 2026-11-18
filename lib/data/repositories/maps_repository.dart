import '../api/api_client.dart';
import '../models/maps.dart';
import '../models/orders.dart' show GeoPoint;

/// Customer-facing map configuration.
///
/// The backend owns the raster provider and proxies every tile, so the app only
/// ever receives an authenticated template plus the required attribution.
class MapsRepository {
  MapsRepository(this._api);

  final ApiClient _api;

  Future<MapConfig> config() async {
    final data = await _api.get<Map<String, dynamic>>(
      '/api/customer/maps/config',
    );
    return MapConfig.fromJson(data);
  }

  /// Real road route between two points.
  ///
  /// Returns null when the backend has no routing provider (or it failed), so
  /// the tracking page shows no path and no distance instead of a straight line
  /// pretending to be a road route.
  Future<MapRoute?> route({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/customer/maps/route',
      body: {
        'origin': {'lat': origin.lat, 'lng': origin.lng},
        'destination': {'lat': destination.lat, 'lng': destination.lng},
      },
    );
    return mapRouteFrom(data);
  }
}
