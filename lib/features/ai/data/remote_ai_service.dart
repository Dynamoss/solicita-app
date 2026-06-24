import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../../../core/utils/typedefs.dart';
import '../domain/ai_service.dart';
import '../domain/entities/ai_suggestion.dart';
import 'llm/llm_client.dart';
import 'local_ai_service.dart';

/// LLM-backed implementation, provider-agnostic.
///
/// It owns the *orchestration* — prompt building, JSON extraction and category
/// validation — and delegates the *transport* to an [LlmClient] (Anthropic,
/// OpenAI, or any compatible gateway). A [LocalAiService] fallback keeps the
/// differential robust: if the network fails or the response can't be parsed,
/// it transparently returns the heuristic suggestion.
class RemoteAiService implements AiService {
  RemoteAiService({
    required LlmClient client,
    LocalAiService fallback = const LocalAiService(),
  })  : _client = client,
        _fallback = fallback;

  final LlmClient _client;
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

    try {
      final text = await _client.complete(_prompt(description));
      final suggestion = _parse(text);
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

  AiSuggestion? _parse(String text) {
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
