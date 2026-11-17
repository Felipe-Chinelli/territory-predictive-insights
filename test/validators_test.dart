import 'package:flutter_test/flutter_test.dart';
import 'package:territory_predictive_insights/core/utils/validators.dart';

void main() {
  group('Validators.description', () {
    test('exige texto', () {
      expect(Validators.description(null), isNotNull);
      expect(Validators.description('   '), isNotNull);
    });

    test('exige mínimo de 15 caracteres', () {
      expect(Validators.description('curto'), contains('15'));
      expect(Validators.description('Poste apagado há uma semana'), isNull);
    });

    test('limita a 280 caracteres', () {
      expect(Validators.description('a' * 281), isNotNull);
      expect(Validators.description('a' * 280), isNull);
    });
  });

  group('Validators.percent', () {
    test('rejeita vazio, texto e fora do intervalo', () {
      expect(Validators.percent('', min: 5, max: 100), isNotNull);
      expect(Validators.percent('abc', min: 5, max: 100), isNotNull);
      expect(Validators.percent('4', min: 5, max: 100), isNotNull);
      expect(Validators.percent('101', min: 5, max: 100), isNotNull);
    });

    test('aceita valor válido', () {
      expect(Validators.percent('20', min: 5, max: 100), isNull);
    });
  });

  group('Validators.critical', () {
    test('precisa ser maior que o limiar de atenção', () {
      expect(Validators.critical('20', '30'), isNotNull);
      expect(Validators.critical('30', '30'), isNotNull);
      expect(Validators.critical('40', '30'), isNull);
    });
  });

  test('requiredChoice', () {
    expect(Validators.requiredChoice<int>(null, 'obrigatório'), 'obrigatório');
    expect(Validators.requiredChoice<int>(1, 'obrigatório'), isNull);
  });
}
