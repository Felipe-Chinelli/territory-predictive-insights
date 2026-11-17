import 'package:flutter_test/flutter_test.dart';
import 'package:territory_predictive_insights/core/utils/anonymizer.dart';

void main() {
  group('Anonymizer', () {
    test('remove e-mail', () {
      final out = Anonymizer.redact('Falar com ana.silva@exemplo.com.br sobre o poste');
      expect(out.contains('@'), isFalse);
      expect(out, contains('[e-mail removido]'));
    });

    test('remove CPF com e sem pontuação', () {
      expect(Anonymizer.redact('CPF 123.456.789-09 do morador'), contains('[documento removido]'));
      expect(Anonymizer.redact('CPF 12345678909'), contains('[documento removido]'));
    });

    test('remove telefone celular', () {
      final out = Anonymizer.redact('Ligue para (11) 98765-4321 ou 11 91234-5678');
      expect(out.contains('98765'), isFalse);
      expect(out.contains('91234'), isFalse);
    });

    test('mantém texto sem dados pessoais', () {
      const text = 'Buraco grande na rua principal perto da escola';
      expect(Anonymizer.redact(text), text);
      expect(Anonymizer.containsPersonalData(text), isFalse);
    });
  });
}
