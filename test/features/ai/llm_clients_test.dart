import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solicita_app/features/ai/data/llm/anthropic_client.dart';
import 'package:solicita_app/features/ai/data/llm/llm_client.dart';
import 'package:solicita_app/features/ai/data/llm/openai_client.dart';

class _MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _response(Map<String, dynamic> body) =>
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: ''),
      data: body,
      statusCode: 200,
    );

void main() {
  late _MockDio dio;

  setUpAll(() => registerFallbackValue(Options()));
  setUp(() => dio = _MockDio());

  // Captures the (headers, body) actually sent on the wire.
  ({Map<String, dynamic>? headers, Map<String, dynamic>? data}) capture() {
    final verification = verify(
      () => dio.post<Map<String, dynamic>>(
        captureAny(),
        options: captureAny(named: 'options'),
        data: captureAny(named: 'data'),
      ),
    );
    final args = verification.captured;
    final options = args[1] as Options;
    return (
      headers: options.headers?.cast<String, dynamic>(),
      data: args[2] as Map<String, dynamic>?,
    );
  }

  group('AnthropicClient', () {
    test('usa o protocolo da Anthropic e lê content[0].text', () async {
      when(() => dio.post<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => _response({
            'content': [
              {'type': 'text', 'text': 'olá da anthropic'},
            ],
          }));

      final client = AnthropicClient(dio: dio, apiKey: 'sk-ant');
      final text = await client.complete('classifique isso');

      expect(text, 'olá da anthropic');

      final sent = capture();
      expect(sent.headers?['x-api-key'], 'sk-ant');
      expect(sent.headers?['anthropic-version'], '2023-06-01');
      expect(sent.headers, isNot(contains('authorization')));
      expect((sent.data?['messages'] as List).first['content'],
          'classifique isso');
    });

    test('resposta sem texto lança LlmException', () async {
      when(() => dio.post<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => _response({'content': <dynamic>[]}));

      final client = AnthropicClient(dio: dio, apiKey: 'sk-ant');
      expect(() => client.complete('x'), throwsA(isA<LlmException>()));
    });
  });

  group('OpenAiClient', () {
    test('usa Bearer e lê choices[0].message.content', () async {
      when(() => dio.post<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => _response({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'olá da openai'},
              },
            ],
          }));

      final client = OpenAiClient(dio: dio, apiKey: 'sk-oai');
      final text = await client.complete('classifique isso');

      expect(text, 'olá da openai');

      final sent = capture();
      expect(sent.headers?['authorization'], 'Bearer sk-oai');
      expect(sent.headers, isNot(contains('x-api-key')));
    });
  });
}
