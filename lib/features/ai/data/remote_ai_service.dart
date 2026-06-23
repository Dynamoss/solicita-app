import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/typedefs.dart';
import '../domain/ai_service.dart';
import '../domain/entities/ai_suggestion.dart';
import 'local_ai_service.dart';

/// LLM-backed implementation (Anthropic Messages API).
///
/// It wraps a [LocalAiService] fallback: if the key is missing, the network
/// fails, or the response can't be parsed, it transparently returns the
/// heuristic suggestion. This keeps the differential robust for evaluation
/// without requiring a real key.
class RemoteAiService implements AiService {
  RemoteAiService({
    required Dio dio,
    LocalAiService fallback = const LocalAiService(),
  })  : _dio = dio,
        _fallback = fallback;

  final Dio _dio;
  final LocalAiService _fallback;

  static const _categories = [
    'Acesso/Login',
    'Financeiro',
    'Infraestrutura',
    'Hardware',
    'Software',
    'Atendimento',
    'Outros',
  ];

  @override
  ResultFuture<AiSuggestion> suggest(String description) async {
    if (description.trim().isEmpty) {
      return _fallback.suggest(description);
    }
    if (!AppConfig.hasAiKey) {
      return _fallback.suggest(description);
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConfig.aiBaseUrl,
        options: Options(
          headers: {
            'x-api-key': AppConfig.aiApiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': AppConfig.aiModel,
          'max_tokens': 256,
          'messages': [
            {'role': 'user', 'content': _prompt(description)},
          ],
        },
      );

      final suggestion = _parse(response.data);
      return suggestion != null ? Right(suggestion) : _fallback.suggest(description);
    } catch (_) {
      // Network/auth/parse failure → degrade gracefully.
      return _fallback.suggest(description);
    }
  }

  String _prompt(String description) => '''
Você classifica chamados de suporte. Categorias válidas: ${_categories.join(', ')}.
Responda APENAS com um JSON no formato {"category": "<categoria>", "summary": "<resumo de até 120 caracteres>"}.
Descrição do chamado: "$description"
''';

  AiSuggestion? _parse(Map<String, dynamic>? data) {
    final content = (data?['content'] as List?)?.firstOrNull;
    final text = (content as Map?)?['text'] as String?;
    if (text == null) return null;

    final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
    if (match == null) return null;

    try {
      final json = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      final category = json['category'] as String?;
      final summary = json['summary'] as String?;
      if (category == null || summary == null) return null;
      return AiSuggestion(
        category: _categories.contains(category) ? category : 'Outros',
        summary: summary,
      );
    } catch (_) {
      return null;
    }
  }
}
