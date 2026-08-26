/// Valida CPF pelo algoritmo de dígito verificador
bool validarCpf(String cpf) {
  // Remove símbolos
  String cpfLimpo = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  // Deve ter 11 dígitos
  if (cpfLimpo.length != 11) return false;

  // Não pode ter todos os dígitos iguais
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpfLimpo)) return false;

  // Calcula primeiro dígito verificador
  int soma = 0;
  for (int i = 0; i < 9; i++) {
    soma += int.parse(cpfLimpo[i]) * (10 - i);
  }
  int digito1 = 11 - (soma % 11);
  digito1 = digito1 > 9 ? 0 : digito1;

  // Calcula segundo dígito verificador
  soma = 0;
  for (int i = 0; i < 10; i++) {
    soma += int.parse(cpfLimpo[i]) * (11 - i);
  }
  int digito2 = 11 - (soma % 11);
  digito2 = digito2 > 9 ? 0 : digito2;

  // Compara
  return digito1 == int.parse(cpfLimpo[9]) &&
      digito2 == int.parse(cpfLimpo[10]);
}
