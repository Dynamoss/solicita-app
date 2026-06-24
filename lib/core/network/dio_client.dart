import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Reads the current session token (or null). Kept as a function so the Dio
/// instance doesn't depend on the auth feature, avoiding a DI cycle.
typedef TokenProvider = Future<String?> Function();

/// Centralised [Dio] construction with the auth interceptor and (debug-only)
/// logging. Single source of truth for timeouts and default headers.
abstract final class DioFactory {
  static Dio create({
    required String baseUrl,
    required TokenProvider tokenProvider,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {'Content-Type': 'application/json'},
        // json-server returns 404 (not an exception) for empty results in some
        // routes; let the data source decide what a "bad" status is.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    _addDebugLogging(dio);
    return dio;
  }

  /// [Dio] for third-party calls (e.g. LLM providers), reached by absolute URL.
  ///
  /// Deliberately built WITHOUT the session auth interceptor: the app's bearer
  /// token must never leak to an external service. Those APIs authenticate with
  /// their own key, set per-request by each `LlmClient`.
  static Dio createExternal() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 8),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _addDebugLogging(dio);
    return dio;
  }

  static void _addDebugLogging(Dio dio) {
    if (kDebugMode) {
      dio.interceptors.add(
        // requestHeader: false so API keys / tokens never hit the debug log.
        LogInterceptor(requestHeader: false, requestBody: true, responseBody: false),
      );
    }
  }
}
