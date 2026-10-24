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
  for (int posicao = 0; posicao < 9; posicao++) {
    soma += int.parse(cpfLimpo[posicao]) * (10 - posicao);
  }
  int digito1 = 11 - (soma % 11);
  digito1 = digito1 > 9 ? 0 : digito1;

  // Calcula segundo dígito verificador
  soma = 0;
  for (int posicao = 0; posicao < 10; posicao++) {
    soma += int.parse(cpfLimpo[posicao]) * (11 - posicao);
  }
  int digito2 = 11 - (soma % 11);
  digito2 = digito2 > 9 ? 0 : digito2;

  // Compara
  return digito1 == int.parse(cpfLimpo[9]) &&
      digito2 == int.parse(cpfLimpo[10]);
}

/// Tela "Nova senha" (recuperação): lista de requisitos mostrada ao vivo.
bool senhaTemCaractereEspecial(String senha) => RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]').hasMatch(senha);

bool senhaTemMinimoCaracteres(String senha) => senha.length >= 8;

bool senhaTemMaiusculaMinusculaNumero(String senha) =>
    RegExp(r'[A-Z]').hasMatch(senha) &&
    RegExp(r'[a-z]').hasMatch(senha) &&
    RegExp(r'\d').hasMatch(senha);

bool senhaAtendeRequisitos(String senha) =>
    senhaTemCaractereEspecial(senha) &&
    senhaTemMinimoCaracteres(senha) &&
    senhaTemMaiusculaMinusculaNumero(senha);


/// Devolve a mensagem de erro, ou null se a senha for válida.
String? validarSenhaCadastro(String? senha) {
  if (senha == null || senha.isEmpty) return 'Digite uma senha';
  if (senha.length < 8) return 'A senha deve ter pelo menos 8 caracteres';
  if (senha.length > 15) return 'A senha deve possuir menos que 15 caracteres';
  if (!RegExp(r'[A-Za-z]').hasMatch(senha)) {
    return 'A senha deve conter pelo menos uma letra';
  }
  if (!RegExp(r'\d').hasMatch(senha)) return 'A senha deve conter pelo menos um número';
  return null;
}
