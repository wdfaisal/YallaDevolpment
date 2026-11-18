import '../../core/utils/json.dart';
import 'orders.dart' show GeoPoint;

/// Server-owned map configuration (`GET /api/customer/maps/config`).
///
/// The backend is the only place that knows the raster provider and any
/// provider key, so the app never embeds a tile URL of its own.
class MapConfig {
  const MapConfig({
    required this.configured,
    required this.tileUrl,
    required this.attribution,
    required this.minZoom,
    required this.maxZoom,
    required this.defaultCenter,
    required this.defaultZoom,
    required this.geocoding,
    required this.routing,
  });

  factory MapConfig.fromJson(Map<String, dynamic> json) {
    return MapConfig(
      configured: asBool(json['configured']),
      tileUrl: asStringOrNull(json['tileUrl']),
      attribution: asStringOrNull(json['attribution']),
      minZoom: asDouble(json['minZoom'], 2),
      maxZoom: asDouble(json['maxZoom'], 19),
      defaultCenter: GeoPoint.fromJson(
        asMap(json['defaultCenter'], 'defaultCenter'),
      ),
      defaultZoom: asDouble(json['defaultZoom'], 12),
      geocoding: asBool(json['geocoding']),
      routing: asBool(json['routing']),
    );
  }

  /// True only when the backend has a raster source it can actually serve.
  final bool configured;

  /// Authenticated proxy template, e.g. `/api/customer/maps/tiles/{z}/{x}/{y}`.
  final String? tileUrl;

  /// Attribution the provider requires, owned by the backend.
  final String? attribution;

  final double minZoom;
  final double maxZoom;
  final GeoPoint defaultCenter;
  final double defaultZoom;
  final bool geocoding;
  final bool routing;
}

/// Everything the tracking map needs to draw the server-owned raster layer.
class MapTiles {
  const MapTiles({
    required this.urlTemplate,
    required this.headers,
    this.attribution,
    this.minZoom = 2,
    this.maxZoom = 19,
  });

  final String urlTemplate;

  /// Authorisation for the tile proxy. Every tile is fetched with the
  /// customer's own session token; the backend never exposes the provider key.
  final Map<String, String> headers;

  final String? attribution;
  final double minZoom;
  final double maxZoom;
}

/// A real road route returned by the backend routing provider.
///
/// The geometry is the provider's own WGS-84 path, so the map draws the roads
/// the captain will actually drive instead of a straight line. `null` is
/// returned by [mapRouteFrom] when the server has no routing provider, so the
/// page never shows a fabricated path or distance.
class MapRoute {
  const MapRoute({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
  });

  factory MapRoute.fromJson(Map<String, dynamic> json) {
    return MapRoute(
      distanceKm: asDouble(json['distanceKm']),
      durationMin: asInt(json['durationMin']),
      points: mapList(json['geometry'], GeoPoint.fromJson),
    );
  }

  /// Road distance in kilometres as reported by the provider.
  final double distanceKm;

  /// Road duration in whole minutes as reported by the provider.
  final int durationMin;

  /// Ordered path of the route.
  final List<GeoPoint> points;
}

/// Reads `{ available, route }` from `POST /api/customer/maps/route`.
///
/// A route with fewer than two points cannot be drawn and is treated as
/// unavailable rather than replaced with a synthetic line.
MapRoute? mapRouteFrom(Map<String, dynamic> json) {
  if (!asBool(json['available'])) return null;
  final route = asMapOrNull(json['route']);
  if (route == null) return null;
  final parsed = MapRoute.fromJson(route);
  return parsed.points.length < 2 ? null : parsed;
}

/// Turns the backend config into tile wiring, or null when the server has no
/// raster source (the page then shows its explicit "map unavailable" state).
MapTiles? mapTilesFrom(
  MapConfig config, {
  required String apiBaseUrl,
  String? token,
}) {
  final path = config.tileUrl;
  if (!config.configured || path == null || path.isEmpty) return null;

  final isAbsolute = path.startsWith('http://') || path.startsWith('https://');
  return MapTiles(
    urlTemplate: isAbsolute ? path : '$apiBaseUrl$path',
    headers: token == null || token.isEmpty
        ? const {}
        : {'Authorization': 'Bearer $token'},
    attribution: config.attribution,
    minZoom: config.minZoom,
    maxZoom: config.maxZoom,
  );
}
