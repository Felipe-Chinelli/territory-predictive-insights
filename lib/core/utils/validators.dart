/// Validadores de formulário (funções puras, fáceis de testar).
class Validators {
  const Validators._();

  static String? requiredChoice<T>(T? value, String message) =>
      value == null ? message : null;

  static String? description(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Descreva o problema para registrar a ocorrência.';
    }
    if (text.length < 15) {
      return 'Escreva ao menos 15 caracteres (faltam ${15 - text.length}).';
    }
    if (text.length > 280) {
      return 'Use no máximo 280 caracteres.';
    }
    return null;
  }

  static String? percent(String? value, {required int min, required int max}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Informe um valor.';
    }
    final n = int.tryParse(text);
    if (n == null) {
      return 'Use apenas números inteiros.';
    }
    if (n < min || n > max) {
      return 'O valor deve estar entre $min e $max.';
    }
    return null;
  }

  /// Limiar crítico precisa ser maior que o limiar de atenção.
  static String? critical(String? value, String? attention) {
    final base = percent(value, min: 10, max: 300);
    if (base != null) {
      return base;
    }
    final c = int.parse(value!.trim());
    final a = int.tryParse((attention ?? '').trim());
    if (a != null && c <= a) {
      return 'Deve ser maior que o limiar de atenção ($a%).';
    }
    return null;
  }
}
