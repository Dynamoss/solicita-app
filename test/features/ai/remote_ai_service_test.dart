import 'package:flutter_test/flutter_test.dart';
import 'package:solicita_app/features/ai/data/llm/llm_client.dart';
import 'package:solicita_app/features/ai/data/remote_ai_service.dart';

/// Stub transport: returns a canned completion, or throws to simulate a
/// network/auth failure. Keeps the orchestration test free of any real HTTP.
class _StubLlmClient implements LlmClient {
  _StubLlmClient.returns(this._text) : _error = null;
  _StubLlmClient.throwsError() : _text = null, _error = const LlmException('boom');

  final String? _text;
  final Object? _error;

  @override
  Future<String> complete(String prompt) async {
    if (_error != null) throw _error;
    return _text!;
  }
}

void main() {
  group('RemoteAiService (orquestração, provider-agnóstica)', () {
    test('parseia o JSON da resposta do LLM em AiSuggestion', () async {
      final service = RemoteAiService(
        client: _StubLlmClient.returns(
          'Claro! {"category": "Financeiro", "summary": "Boleto vencido."}',
        ),
      );

      final result = await service.suggest('Não consegui pagar o boleto.');
      final suggestion = result.getOrElse((_) => throw Exception());

      expect(suggestion.category, 'Financeiro');
      expect(suggestion.summary, 'Boleto vencido.');
      expect(suggestion.fromFallback, isFalse);
    });

    test('categoria desconhecida do LLM é normalizada para "Outros"', () async {
      final service = RemoteAiService(
        client: _StubLlmClient.returns(
          '{"category": "Inexistente", "summary": "x"}',
        ),
      );

      final suggestion =
          (await service.suggest('qualquer')).getOrElse((_) => throw Exception());
      expect(suggestion.category, 'Outros');
    });

    test('falha de transporte cai no heurístico (fromFallback)', () async {
      final service = RemoteAiService(client: _StubLlmClient.throwsError());

      final suggestion = (await service.suggest('Esqueci minha senha de login.'))
          .getOrElse((_) => throw Exception());

      expect(suggestion.fromFallback, isTrue);
      expect(suggestion.category, 'Acesso/Login');
    });

    test('resposta sem JSON cai no heurístico', () async {
      final service = RemoteAiService(
        client: _StubLlmClient.returns('desculpe, não posso ajudar'),
      );

      final suggestion = (await service.suggest('A vpn caiu de novo.'))
          .getOrElse((_) => throw Exception());
      expect(suggestion.fromFallback, isTrue);
      expect(suggestion.category, 'Infraestrutura');
    });

    test('descrição vazia nem chama o LLM (vai direto ao fallback)', () async {
      // Stub that would explode if called — proves the short-circuit.
      final service = RemoteAiService(client: _StubLlmClient.throwsError());
      final result = await service.suggest('   ');
      expect(result.isLeft(), isTrue);
    });
  });
}
