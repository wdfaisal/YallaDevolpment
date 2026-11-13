/// Normalized API failure. `code` is the stable backend error code
/// (`ORDER_NOT_FOUND`, `SESSION_EXPIRED`, …) and `fields` carries per-field
/// validation messages returned by Zod.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.code = 'UNKNOWN',
    this.status,
    this.fields,
    this.requestId,
  });

  final String message;
  final String code;
  final int? status;
  final Map<String, String>? fields;
  final String? requestId;

  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;

  /// First field message, when present — used inline in forms.
  String? get fieldMessage => fields == null || fields!.isEmpty ? null : fields!.values.first;

  @override
  String toString() => 'ApiException($status/$code): $message';
}
