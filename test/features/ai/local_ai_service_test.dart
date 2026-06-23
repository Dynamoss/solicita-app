import 'package:flutter_test/flutter_test.dart';
import 'package:solicita_app/core/error/failures.dart';
import 'package:solicita_app/features/ai/data/local_ai_service.dart';

void main() {
  const service = LocalAiService();

  group('LocalAiService', () {
    test('categoriza por palavras-chave (Acesso/Login)', () async {
      final result = await service.suggest(
        'Esqueci minha senha e não consigo fazer login no sistema.',
      );

      final suggestion = result.getOrElse((_) => throw Exception());
      expect(suggestion.category, 'Acesso/Login');
      expect(suggestion.fromFallback, isTrue);
    });

    test('categoriza Infraestrutura', () async {
      final result = await service.suggest(
        'A internet do escritório está com lentidão e a vpn caiu.',
      );
      expect(result.getOrElse((_) => throw Exception()).category,
          'Infraestrutura');
    });

    test('cai em "Outros" quando nada casa', () async {
      final result = await service.suggest('Mensagem genérica qualquer aqui.');
      expect(result.getOrElse((_) => throw Exception()).category, 'Outros');
    });

    test('resumo nunca excede o limite e termina pontuado', () async {
      final longText = 'a' * 300;
      final suggestion =
          (await service.suggest(longText)).getOrElse((_) => throw Exception());
      expect(suggestion.summary.length, lessThanOrEqualTo(121));
      expect(suggestion.summary.endsWith('...'), isTrue);
    });

    test('descrição vazia retorna ValidationFailure', () async {
      final result = await service.suggest('   ');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) {});
    });
  });
}
