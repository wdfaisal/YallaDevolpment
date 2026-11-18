import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/data/models/maps.dart';

Map<String, dynamic> _payload({
  bool configured = true,
  String? tileUrl = '/api/customer/maps/tiles/{z}/{x}/{y}',
  String? attribution = '(c) OpenStreetMap contributors',
}) {
  return {
    'provider': configured ? 'raster' : 'none',
    'configured': configured,
    'tileUrl': tileUrl,
    'attribution': attribution,
    'minZoom': 2,
    'maxZoom': 19,
    'defaultCenter': {'lat': 15.5007, 'lng': 32.5599},
    'defaultZoom': 12,
    'geocoding': true,
    'routing': true,
  };
}

void main() {
  group('MapConfig', () {
    test('parses the backend config', () {
      final config = MapConfig.fromJson(_payload());

      expect(config.configured, isTrue);
      expect(config.tileUrl, '/api/customer/maps/tiles/{z}/{x}/{y}');
      expect(config.attribution, '(c) OpenStreetMap contributors');
      expect(config.minZoom, 2);
      expect(config.maxZoom, 19);
      expect(config.defaultCenter.lat, closeTo(15.5007, 1e-9));
      expect(config.defaultCenter.lng, closeTo(32.5599, 1e-9));
      expect(config.defaultZoom, 12);
      expect(config.geocoding, isTrue);
      expect(config.routing, isTrue);
    });

    test('keeps an unconfigured map honest', () {
      final config = MapConfig.fromJson(
        _payload(configured: false, tileUrl: null, attribution: null),
      );

      expect(config.configured, isFalse);
      expect(config.tileUrl, isNull);
      expect(config.attribution, isNull);
    });
  });

  group('mapTilesFrom', () {
    test('resolves the authenticated template against the API origin', () {
      final tiles = mapTilesFrom(
        MapConfig.fromJson(_payload()),
        apiBaseUrl: 'http://localhost:4000',
        token: 'token-123',
      );

      expect(tiles, isNotNull);
      expect(
        tiles!.urlTemplate,
        'http://localhost:4000/api/customer/maps/tiles/{z}/{x}/{y}',
      );
      expect(tiles.headers, {'Authorization': 'Bearer token-123'});
      expect(tiles.attribution, '(c) OpenStreetMap contributors');
      expect(tiles.minZoom, 2);
      expect(tiles.maxZoom, 19);
    });

    test('keeps an absolute template untouched', () {
      final tiles = mapTilesFrom(
        MapConfig.fromJson(
            _payload(tileUrl: 'https://maps.example.com/{z}/{x}/{y}')),
        apiBaseUrl: 'http://localhost:4000',
        token: 'token-123',
      );

      expect(tiles!.urlTemplate, 'https://maps.example.com/{z}/{x}/{y}');
    });

    test('omits authorization when no session token is stored', () {
      final tiles = mapTilesFrom(
        MapConfig.fromJson(_payload()),
        apiBaseUrl: 'http://localhost:4000',
      );

      expect(tiles!.headers, isEmpty);
    });

    test('returns null when the backend has no raster source', () {
      final tiles = mapTilesFrom(
        MapConfig.fromJson(
          _payload(configured: false, tileUrl: null, attribution: null),
        ),
        apiBaseUrl: 'http://localhost:4000',
        token: 'token-123',
      );

      expect(tiles, isNull);
    });
  });

  group('mapRouteFrom', () {
    Map<String, dynamic> response({bool available = true, int points = 2}) {
      return {
        'available': available,
        'route': available
            ? {
                'distanceKm': 13.89,
                'durationMin': 22,
                'geometry': [
                  for (var i = 0; i < points; i++)
                    {'lat': 15.50 + i * 0.01, 'lng': 32.56 - i * 0.01},
                ],
              }
            : null,
      };
    }

    test('parses the provider geometry and road metrics', () {
      final route = mapRouteFrom(response());

      expect(route, isNotNull);
      expect(route!.distanceKm, closeTo(13.89, 1e-9));
      expect(route.durationMin, 22);
      expect(route.points, hasLength(2));
      expect(route.points.first.lat, closeTo(15.50, 1e-9));
      expect(route.points.last.lng, closeTo(32.55, 1e-9));
    });

    test('returns null when the backend has no routing provider', () {
      expect(mapRouteFrom(response(available: false)), isNull);
    });

    test('returns null for geometry that cannot be drawn', () {
      expect(mapRouteFrom(response(points: 1)), isNull);
    });
  });
}
