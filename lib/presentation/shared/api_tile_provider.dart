import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

/// Loads one tile's bytes. Injected in tests; production uses Dio.
typedef TileLoader = Future<Uint8List> Function(
  String url,
  Map<String, String> headers,
);

/// Raster tiles fetched through the app's own HTTP client.
///
/// `flutter_map`'s `NetworkTileProvider` is deliberately not used:
///
/// * on native platforms it cancels every in-flight request whose tile is
///   pruned (`abortObsoleteRequests`). That is invisible on the web, where
///   requests are not cancellable, but on a phone a camera fit that disposes
///   the first tiles can starve the layer and leave it blank;
/// * on native platforms it enables a disk cache that initialises through
///   `path_provider` and a background isolate. If that initialisation never
///   completes, every tile read awaits a future that never resolves — again a
///   blank layer, and again web-only code paths hide it.
///
/// This provider keeps the tile path identical on every platform:
///
/// * Dio, the same HTTP stack the rest of the app already uses on Android;
/// * no cancellation of in-flight tiles;
/// * a small in-memory LRU, no disk cache, isolates or plugins;
/// * two retries per tile before it reports a failure;
/// * explicit failure reporting so the tracking page can say the map could not
///   be loaded instead of showing an unexplained empty area.
class ApiTileProvider extends TileProvider {
  ApiTileProvider({
    Dio? dio,
    TileLoader? loader,
    super.headers,
    this.maxCachedTiles = 160,
    this.retries = 2,
    this.onTileLoaded,
    this.onTileFailed,
  })  : assert(dio != null || loader != null, 'dio or loader is required'),
        _dio = dio,
        _loader = loader;

  final Dio? _dio;
  final TileLoader? _loader;

  /// Bounded so a long tracking session cannot grow without limit.
  final int maxCachedTiles;

  /// Extra attempts after the first one. Two retries cover a dropped
  /// connection without delaying the layer for long.
  final int retries;

  final void Function()? onTileLoaded;
  final void Function()? onTileFailed;

  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _ApiTileImage(provider: this, url: getTileUrl(coordinates, options));

  /// Tile bytes for [url], served from the in-memory cache when possible.
  @visibleForTesting
  Future<Uint8List> bytesFor(String url) async {
    final cached = _cache.remove(url);
    if (cached != null) {
      // Re-insert to keep the LRU order.
      _cache[url] = cached;
      return cached;
    }
    final bytes = await _download(url);
    _cache[url] = bytes;
    while (_cache.length > maxCachedTiles) {
      _cache.remove(_cache.keys.first);
    }
    return bytes;
  }

  Future<Uint8List> _download(String url) async {
    Object? failure;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final bytes = await _fetch(url);
        onTileLoaded?.call();
        return bytes;
      } catch (error) {
        failure = error;
        // Reachable from `adb logcat` on a release Android build, which is the
        // only way to see why the layer is empty on a device.
        debugPrint(
          'Map tile $url failed (attempt ${attempt + 1}/${retries + 1}): $error',
        );
        if (attempt < retries) {
          await Future<void>.delayed(
            Duration(milliseconds: 200 * (attempt + 1)),
          );
        }
      }
    }
    onTileFailed?.call();
    throw TileFetchException(url, failure);
  }

  Future<Uint8List> _fetch(String url) async {
    final loader = _loader;
    if (loader != null) return loader(url, headers);

    final response = await _dio!.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: {
          'Accept': 'image/png,image/jpeg,image/webp,image/*;q=0.8',
          ...headers,
        },
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('The tile provider returned an empty body.');
    }
    return Uint8List.fromList(data);
  }

  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }
}

/// One failed tile after every retry. flutter_map treats it as a tile error and
/// keeps the rest of the layer; the page decides whether to surface it.
class TileFetchException implements Exception {
  const TileFetchException(this.url, this.cause);

  final String url;
  final Object? cause;

  @override
  String toString() => 'TileFetchException($url): $cause';
}

@immutable
class _ApiTileImage extends ImageProvider<_ApiTileImage> {
  const _ApiTileImage({required this.provider, required this.url});

  final ApiTileProvider provider;
  final String url;

  @override
  Future<_ApiTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_ApiTileImage>(this);

  @override
  ImageStreamCompleter loadImage(
      _ApiTileImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _decode(decode),
      scale: 1,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<String>('Tile URL', url),
      ],
    );
  }

  Future<ui.Codec> _decode(ImageDecoderCallback decode) async {
    final bytes = await provider.bytesFor(url);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is _ApiTileImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
