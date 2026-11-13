import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/utils/media_url.dart';

void main() {
  group('resolveMediaUrl', () {
    test('prefixes backend-relative media paths with the API origin', () {
      expect(
        resolveMediaUrl('/api/media/images/a.jpg', baseUrl: 'http://localhost:4000'),
        'http://localhost:4000/api/media/images/a.jpg',
      );
    });

    test('joins paths without a leading slash', () {
      expect(
        resolveMediaUrl('api/media/images/a.png', baseUrl: 'http://localhost:4000'),
        'http://localhost:4000/api/media/images/a.png',
      );
    });

    test('ignores a trailing slash on the configured base URL', () {
      expect(
        resolveMediaUrl('/api/media/images/a.webp', baseUrl: 'http://localhost:4000/'),
        'http://localhost:4000/api/media/images/a.webp',
      );
    });

    test('keeps absolute URLs untouched', () {
      const url = 'https://cdn.example.com/banner.png';
      expect(resolveMediaUrl(url, baseUrl: 'http://localhost:4000'), url);
    });

    test('upgrades protocol-relative URLs to https', () {
      expect(
        resolveMediaUrl('//cdn.example.com/banner.png', baseUrl: 'http://localhost:4000'),
        'https://cdn.example.com/banner.png',
      );
    });

    test('keeps inline data URLs untouched', () {
      const url = 'data:image/png;base64,AAAA';
      expect(resolveMediaUrl(url, baseUrl: 'http://localhost:4000'), url);
    });

    test('returns null for missing or blank values', () {
      expect(resolveMediaUrl(null), isNull);
      expect(resolveMediaUrl('   '), isNull);
    });
  });
}
