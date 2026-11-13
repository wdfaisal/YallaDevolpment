/// Safe JSON accessors used by every model. The API contract is authoritative;
/// these helpers fail loudly on a malformed payload instead of silently
/// rendering invented defaults.
Map<String, dynamic> asMap(dynamic value, [String field = 'payload']) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('Expected object for "$field"');
}

Map<String, dynamic>? asMapOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

List<dynamic> asList(dynamic value, [String field = 'payload']) {
  if (value is List) return value;
  throw FormatException('Expected list for "$field"');
}

List<T> mapList<T>(dynamic value, T Function(Map<String, dynamic>) build) {
  if (value == null) return const [];
  if (value is! List) return const [];
  return value
      .whereType<Object>()
      .map((item) => build(asMap(item)))
      .toList(growable: false);
}

String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == 'true' || value == '1';
  return fallback;
}
