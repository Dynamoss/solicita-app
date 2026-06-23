import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/typedefs.dart';
import '../domain/ai_service.dart';
import '../domain/entities/ai_suggestion.dart';

/// Deterministic, offline fallback for the AI feature.
///
/// Keyword-based categorization + extractive summary. It needs no network or
/// key, so the differential degrades gracefully (and unit tests are stable).
class LocalAiService implements AiService {
  const LocalAiService();

  /// Ordered so earlier (more specific) categories win on ties.
  static const Map<String, List<String>> _rules = {
    'Acesso/Login': ['senha', 'login', 'acesso', 'autenticação', 'bloqueado', 'usuário'],
    'Financeiro': ['pagamento', 'boleto', 'fatura', 'cobrança', 'reembolso', 'nota fiscal'],
    'Infraestrutura': ['rede', 'internet', 'servidor', 'wifi', 'conexão', 'lentidão', 'vpn'],
    'Hardware': ['notebook', 'computador', 'impressora', 'monitor', 'mouse', 'teclado', 'celular'],
    'Software': ['aplicativo', 'sistema', 'erro', 'bug', 'instalar', 'atualização', 'tela'],
    'Atendimento': ['atendimento', 'agendamento', 'consulta', 'médico', 'paciente', 'exame'],
  };

  @override
  ResultFuture<AiSuggestion> suggest(String description) async {
    final text = description.toLowerCase();

    var bestCategory = 'Outros';
    var bestScore = 0;
    for (final entry in _rules.entries) {
      final score = entry.value.where(text.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    if (description.trim().isEmpty) {
      return const Left(
        ValidationFailure('Descreva a solicitação para gerar a sugestão.'),
      );
    }

    return Right(
      AiSuggestion(
        category: bestCategory,
        summary: _summarize(description),
        fromFallback: true,
      ),
    );
  }

  String _summarize(String description) {
    final clean = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    final firstSentence = clean.split(RegExp(r'(?<=[.!?])\s')).first;
    final base = firstSentence.length <= 120
        ? firstSentence
        : '${firstSentence.substring(0, 117)}...';
    return base.endsWith('.') || base.endsWith('...') ? base : '$base.';
  }
}
