import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solicita_app/core/network/dio_client.dart';

/// Captures the final [RequestOptions] and short-circuits with a canned 200,
/// so we can inspect exactly which headers would go on the wire — no real I/O.
class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DioFactory', () {
    test('create() anexa o Bearer da sessão às requisições da API', () async {
      final dio = DioFactory.create(
        baseUrl: 'http://localhost:3000',
        tokenProvider: () async => 'session-token',
      );
      final adapter = _CaptureAdapter();
      dio.httpClientAdapter = adapter;

      await dio.get<dynamic>('/requests');

      expect(adapter.captured!.headers['Authorization'], 'Bearer session-token');
    });

    test('createExternal() NÃO anexa o token de sessão (sem vazamento p/ LLM)',
        () async {
      final dio = DioFactory.createExternal();
      final adapter = _CaptureAdapter();
      dio.httpClientAdapter = adapter;

      await dio.post<dynamic>(
        'https://api.anthropic.com/v1/messages',
        data: const {'ping': true},
      );

      final headers = adapter.captured!.headers;
      // Nenhuma variação de capitalização do header de autorização deve estar
      // presente — o Dio externo não conhece o token de sessão.
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers.containsKey('authorization'), isFalse);
    });
  });
}
