import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/presentation/shared/api_tile_provider.dart';

/// A tile-shaped payload. The provider never decodes bytes itself, so any
/// non-empty payload is enough for these tests.
Uint8List _tile(int fill) => Uint8List.fromList(List<int>.filled(64, fill));

void main() {
  test('tile bytes are cached and reused without a second request', () async {
    var calls = 0;
    final provider = ApiTileProvider(
      loader: (url, headers) async {
        calls++;
        return _tile(calls);
      },
    );

    final first = await provider.bytesFor('http://api.test/tiles/1/2/3');
    final second = await provider.bytesFor('http://api.test/tiles/1/2/3');

    expect(calls, 1);
    expect(first, second);
  });

  test('the LRU drops the oldest tile once the cache is full', () async {
    final requested = <String>[];
    final provider = ApiTileProvider(
      maxCachedTiles: 2,
      loader: (url, headers) async {
        requested.add(url);
        return _tile(requested.length);
      },
    );

    await provider.bytesFor('a');
    await provider.bytesFor('b');
    await provider.bytesFor('a'); // still cached, no request
    await provider.bytesFor('c'); // evicts 'b' (least recently used)
    await provider.bytesFor('b'); // must be requested again

    expect(requested, ['a', 'b', 'c', 'b']);
  });

  test('a transient failure is retried before the tile is reported', () async {
    var calls = 0;
    var failures = 0;
    final provider = ApiTileProvider(
      retries: 1,
      onTileFailed: () => failures++,
      loader: (url, headers) async {
        calls++;
        if (calls == 1) throw StateError('connection reset');
        return _tile(7);
      },
    );

    final bytes = await provider.bytesFor('http://api.test/tiles/1/2/3');

    expect(calls, 2);
    expect(bytes.length, 64);
    expect(failures, 0);
  });

  test('the session header reaches every tile request', () async {
    Map<String, String>? seen;
    final provider = ApiTileProvider(
      headers: const {'Authorization': 'Bearer session-token'},
      loader: (url, headers) async {
        seen = headers;
        return _tile(1);
      },
    );

    await provider.bytesFor('http://api.test/tiles/1/2/3');

    expect(seen, {'Authorization': 'Bearer session-token'});
  });

  test('a persistent failure throws and reports the tile', () async {
    var failures = 0;
    final provider = ApiTileProvider(
      retries: 2,
      onTileFailed: () => failures++,
      loader: (url, headers) async => throw StateError('offline'),
    );

    await expectLater(
      provider.bytesFor('http://api.test/tiles/1/2/3'),
      throwsA(isA<TileFetchException>()),
    );
    expect(failures, 1);
  });
}
