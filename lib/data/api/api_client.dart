import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/config/env.dart';
import '../../core/utils/json.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Single HTTP entry point for the whole app.
///
/// - unwraps the backend `{ data }` envelope;
/// - attaches the customer Bearer token;
/// - maps every failure to [ApiException] with the stable backend code;
/// - supports cancellation (search) and short-lived GET caching.
class ApiClient {
  ApiClient({required TokenStore tokenStore, String? baseUrl, Dio? dio})
      : _tokenStore = tokenStore,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? Env.apiBaseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 25),
                sendTimeout: const Duration(seconds: 15),
                headers: const {'Accept': 'application/json'},
                responseType: ResponseType.json,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStore.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokenStore;

  /// Invoked once when the backend rejects the session, so state can reset.
  void Function()? onUnauthorized;

  final Map<String, _CacheEntry> _cache = {};

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Duration cacheFor = Duration.zero,
  }) async {
    final cacheKey = '$path|${query ?? const {}}';
    if (cacheFor > Duration.zero) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        return cached.value as T;
      }
    }
    final value = await _request<T>(
      () => _dio.get<dynamic>(path, queryParameters: _clean(query), cancelToken: cancelToken),
    );
    if (cacheFor > Duration.zero) {
      _cache[cacheKey] = _CacheEntry(value, DateTime.now().add(cacheFor));
    }
    return value;
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    _invalidate();
    return _request<T>(
      () => _dio.post<dynamic>(path, data: body, queryParameters: _clean(query), cancelToken: cancelToken),
    );
  }

  Future<T> patch<T>(String path, {Object? body}) async {
    _invalidate();
    return _request<T>(() => _dio.patch<dynamic>(path, data: body));
  }

  Future<T> delete<T>(String path, {Object? body}) async {
    _invalidate();
    return _request<T>(() => _dio.delete<dynamic>(path, data: body));
  }

  /// Clears the short-lived catalog cache. Called after any mutation so the
  /// next read reflects the server immediately.
  void invalidateCache() => _invalidate();

  void _invalidate() => _cache.clear();

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.isEmpty) continue;
      cleaned[entry.key] = value;
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<T> _request<T>(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      final body = response.data;
      if (body is Map && body.containsKey('data')) {
        return body['data'] as T;
      }
      return body as T;
    } on DioException catch (error) {
      throw _mapError(error);
    } on FormatException catch (error) {
      throw ApiException(code: 'BAD_RESPONSE', message: error.message);
    }
  }

  ApiException _mapError(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      throw ApiException(code: 'CANCELLED', message: 'Request cancelled', status: 499);
    }
    final response = error.response;
    if (response == null) {
      return ApiException(
        code: 'NETWORK_ERROR',
        message: 'تعذّر الاتصال بالخادم. تحقق من الشبكة.',
      );
    }
    final status = response.statusCode;
    Map<String, String>? fields;
    String message = 'تعذّر إكمال العملية';
    String code = 'HTTP_${status ?? 0}';
    String? requestId;

    final payload = asMapOrNull(response.data);
    final errorBody = payload == null ? null : asMapOrNull(payload['error']);
    if (errorBody != null) {
      code = asString(errorBody['code'], code);
      message = asString(errorBody['message'], message);
      requestId = asStringOrNull(errorBody['requestId']);
      final rawFields = asMapOrNull(errorBody['fields']);
      if (rawFields != null) {
        fields = rawFields.map((key, value) => MapEntry(key, asString(value)));
      }
    }

    if (status == 401) {
      onUnauthorized?.call();
    }
    return ApiException(
      message: message,
      code: code,
      status: status,
      fields: fields,
      requestId: requestId,
    );
  }
}

class _CacheEntry {
  _CacheEntry(this.value, this.expiresAt);

  final Object? value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
