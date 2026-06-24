import 'package:dio/dio.dart';

import 'llm_client.dart';

/// [LlmClient] for the OpenAI Chat Completions API (and compatible gateways).
///
/// Wire format: `Authorization: Bearer` header, a `messages` body, and the
/// completion read from `choices[0].message.content`.
class OpenAiClient implements LlmClient {
  OpenAiClient({
    required Dio dio,
    required String apiKey,
    String? baseUrl,
    String? model,
  })  : _dio = dio,
        _apiKey = apiKey,
        _baseUrl = (baseUrl == null || baseUrl.isEmpty) ? _defaultBaseUrl : baseUrl,
        _model = (model == null || model.isEmpty) ? _defaultModel : model;

  static const _defaultBaseUrl = 'https://api.openai.com/v1/chat/completions';
  static const _defaultModel = 'gpt-4o-mini';

  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;
  final String _model;

  @override
  Future<String> complete(String prompt) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _baseUrl,
      options: Options(
        headers: {
          'authorization': 'Bearer $_apiKey',
          'content-type': 'application/json',
        },
      ),
      data: {
        'model': _model,
        'max_tokens': 256,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      },
    );

    final choice = (response.data?['choices'] as List?)?.firstOrNull;
    final message = (choice as Map?)?['message'] as Map?;
    final text = message?['content'] as String?;
    if (text == null) {
      throw const LlmException('Resposta da OpenAI sem conteúdo de texto.');
    }
    return text;
  }
}
