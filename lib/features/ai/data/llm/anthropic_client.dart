import 'package:dio/dio.dart';

import 'llm_client.dart';

/// [LlmClient] for the Anthropic Messages API.
///
/// Wire format: `x-api-key` + `anthropic-version` headers, a `messages` body,
/// and the completion read from `content[0].text`.
class AnthropicClient implements LlmClient {
  AnthropicClient({
    required Dio dio,
    required String apiKey,
    String? baseUrl,
    String? model,
  })  : _dio = dio,
        _apiKey = apiKey,
        _baseUrl = (baseUrl == null || baseUrl.isEmpty) ? _defaultBaseUrl : baseUrl,
        _model = (model == null || model.isEmpty) ? _defaultModel : model;

  static const _defaultBaseUrl = 'https://api.anthropic.com/v1/messages';
  static const _defaultModel = 'claude-haiku-4-5';
  static const _apiVersion = '2023-06-01';

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
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
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

    final content = (response.data?['content'] as List?)?.firstOrNull;
    final text = (content as Map?)?['text'] as String?;
    if (text == null) {
      throw const LlmException('Resposta da Anthropic sem conteúdo de texto.');
    }
    return text;
  }
}
