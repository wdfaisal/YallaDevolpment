import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../data/models/maps.dart';
import '../data/models/orders.dart' show GeoPoint;
import '../data/repositories/maps_repository.dart';
import 'providers.dart';

final mapsRepositoryProvider = Provider<MapsRepository>(
  (ref) => MapsRepository(ref.watch(apiClientProvider)),
);

/// Raster tile wiring for the tracking map.
///
/// Auto-disposed so every tracking visit re-reads the current session token:
/// the tile proxy authorises each request with the customer's own Bearer token,
/// and a token captured at a previous session would leave the map blank.
final mapTilesProvider = FutureProvider.autoDispose<MapTiles?>((ref) async {
  final config = await ref.watch(mapsRepositoryProvider).config();
  final token = await ref.read(tokenStoreProvider).read();
  return mapTilesFrom(config, apiBaseUrl: Env.apiBaseUrl, token: token);
});

/// One road-route request. Equality on the coordinates keeps the provider
/// stable across rebuilds, so the tracking page asks the backend once per
/// pickup/drop pair instead of on every frame.
class MapRouteQuery {
  const MapRouteQuery({required this.origin, required this.destination});

  final GeoPoint origin;
  final GeoPoint destination;

  @override
  bool operator ==(Object other) {
    return other is MapRouteQuery &&
        other.origin.lat == origin.lat &&
        other.origin.lng == origin.lng &&
        other.destination.lat == destination.lat &&
        other.destination.lng == destination.lng;
  }

  @override
  int get hashCode =>
      Object.hash(origin.lat, origin.lng, destination.lat, destination.lng);
}

/// The real road route the tracking map draws, keyed by its endpoints.
final mapRouteProvider =
    FutureProvider.autoDispose.family<MapRoute?, MapRouteQuery>((ref, query) {
  return ref.watch(mapsRepositoryProvider).route(
        origin: query.origin,
        destination: query.destination,
      );
});
