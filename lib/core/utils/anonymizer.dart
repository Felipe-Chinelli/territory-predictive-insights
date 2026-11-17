/// Remove dados pessoais comuns de textos livres antes de qualquer persistência.
class Anonymizer {
  const Anonymizer._();

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final RegExp _cpf = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
  static final RegExp _phone = RegExp(
    r'(?:\+?55\s?)?(?:\(\d{2}\)|\d{2})\s?9?\d{4}[-\s]?\d{4}(?!\d)',
  );

  static String redact(String input) {
    return input
        .replaceAll(_email, '[e-mail removido]')
        .replaceAll(_cpf, '[documento removido]')
        .replaceAll(_phone, '[telefone removido]');
  }

  static bool containsPersonalData(String input) => redact(input) != input;
}
