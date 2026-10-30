import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'config.dart';
import 'logging/app_log.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient(this.tokens) {
    dio = Dio(
      BaseOptions(
        baseUrl: apiBase,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.data is! FormData && options.data != null && !options.headers.containsKey('Content-Type')) {
            options.headers['Content-Type'] = 'application/json';
          }
          if (options.extra['auth'] == true && tokens.access != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.access}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final options = error.requestOptions;
          final shouldRefresh = response?.statusCode == 401 &&
              options.extra['auth'] == true &&
              options.extra['retried'] != true &&
              tokens.refresh != null;
          if (shouldRefresh) {
            final refreshed = await _refresh();
            if (refreshed) {
              options.extra['retried'] = true;
              options.headers['Authorization'] = 'Bearer ${tokens.access}';
              try {
                final result = await dio.fetch(options);
                return handler.resolve(result);
              } catch (retryError) {
                if (retryError is DioException) return handler.next(retryError);
              }
            } else {
              await tokens.clear();
              onUnauthorized?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
    dio.interceptors.add(_DioLog());
  }

  final TokenStore tokens;
  late final Dio dio;
  void Function()? onUnauthorized;
  Future<bool>? _refreshing;

  Future<bool> _refresh() {
    return _refreshing ??= _refreshOnce().whenComplete(() => _refreshing = null);
  }

  Future<bool> _refreshOnce() async {
    final refresh = tokens.refresh;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: apiBase));
      refreshDio.interceptors.add(_DioLog(logBody: false));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final data = response.data ?? {};
      final access = data['access']?.toString();
      if (access == null || access.isEmpty) return false;
      await tokens.save(access, data['refresh']?.toString() ?? refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<T> get<T>(String path, {bool auth = false, T Function(dynamic data)? parse}) {
    return _send('GET', path, auth: auth, parse: parse);
  }

  Future<T> post<T>(String path, {Object? data, bool auth = false, T Function(dynamic data)? parse}) {
    return _send('POST', path, data: data, auth: auth, parse: parse);
  }

  Future<T> patch<T>(String path, {Object? data, bool auth = false, T Function(dynamic data)? parse}) {
    return _send('PATCH', path, data: data, auth: auth, parse: parse);
  }

  Future<void> delete(String path, {bool auth = false}) async {
    await _send('DELETE', path, auth: auth, parse: (_) {});
  }

  Future<T> _send<T>(
    String method,
    String path, {
    Object? data,
    bool auth = false,
    T Function(dynamic data)? parse,
  }) async {
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method, extra: {'auth': auth}),
      );
      final body = response.data;
      if (parse == null) return body as T;
      return parse(body);
    } on DioException catch (error) {
      throw _toException(error);
    }
  }

  ApiException _toException(DioException error) {
    final status = error.response?.statusCode ?? 0;
    final data = error.response?.data;
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return const ApiException('اتصال به سرور برقرار نشد.');
    }
    if (data is Map) {
      final detail = data['detail'];
      if (detail != null) return ApiException(detail.toString(), status: status);
      final parts = <String>[];
      data.forEach((_, value) {
        if (value is List && value.isNotEmpty) {
          parts.add(value.first.toString());
        } else if (value is String) {
          parts.add(value);
        }
      });
      if (parts.isNotEmpty) return ApiException(parts.join('\n'), status: status);
    }
    if (status == 401) return ApiException('نشست شما منقضی شده است.', status: status);
    return ApiException('خطایی رخ داد.', status: status);
  }
}

class _DioLog extends Interceptor {
  _DioLog({this.logBody = true});

  final bool logBody;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLog.dio('→ ${options.method} ${options.uri}');
    if (logBody && options.data != null) AppLog.dio('  body ${_preview(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLog.dio('← ${response.statusCode} ${response.requestOptions.uri}');
    if (logBody) AppLog.dio('  body ${_preview(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLog.dio('✖ ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.uri}');
    handler.next(err);
  }

  String _preview(Object? data) {
    if (data is FormData) return 'FormData';
    final text = '$data';
    if (text.length <= 500) return text;
    return '${text.substring(0, 500)}…';
  }
}
