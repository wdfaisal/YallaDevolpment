import '../config/env.dart';

/// Turns a media reference from the backend into an absolute URL.
///
/// The API stores and returns root-relative paths such as
/// `/api/media/images/<uuid>.jpg`; those must be served from the API origin,
/// not from the web app origin. Absolute URLs (CDN banners, `data:` images) are
/// returned untouched. Returns `null` for empty input so callers keep showing
/// their own placeholder.
String? resolveMediaUrl(String? raw, {String? baseUrl}) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  // Protocol-relative URL: adopt HTTPS, which every backend/CDN supports.
  if (value.startsWith('//')) return 'https:$value';

  // Inline payloads are already complete.
  if (value.startsWith('data:') || value.startsWith('blob:')) return value;

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return value;

  final base = (baseUrl ?? Env.apiBaseUrl).replaceFirst(RegExp(r'/+$'), '');
  return value.startsWith('/') ? '$base$value' : '$base/$value';
}
