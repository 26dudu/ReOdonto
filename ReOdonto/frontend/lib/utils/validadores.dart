bool validarCpf(String cpf) {
  String cpfLimpo = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  if (cpfLimpo.length != 11) return false;

  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpfLimpo)) return false;

  int soma = 0;
  for (int posicao = 0; posicao < 9; posicao++) {
    soma += int.parse(cpfLimpo[posicao]) * (10 - posicao);
  }
  int digito1 = 11 - (soma % 11);
  digito1 = digito1 > 9 ? 0 : digito1;

  soma = 0;
  for (int posicao = 0; posicao < 10; posicao++) {
    soma += int.parse(cpfLimpo[posicao]) * (11 - posicao);
  }
  int digito2 = 11 - (soma % 11);
  digito2 = digito2 > 9 ? 0 : digito2;

  return digito1 == int.parse(cpfLimpo[9]) &&
      digito2 == int.parse(cpfLimpo[10]);
}

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

String? validarNome(String? nomeDigitado) {
  if (nomeDigitado == null || nomeDigitado.trim().isEmpty) {
    return 'Preencha o nome completo';
  }
  if (nomeDigitado.trim().length < 3) {
    return 'Nome deve ter pelo menos 3 caracteres';
  }
  return null;
}

String? validarEmail(String? emailDigitado) {
  if (emailDigitado == null || emailDigitado.trim().isEmpty) {
    return 'Preencha o email';
  }
  final regex = RegExp(
    r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$',
    caseSensitive: false,
  );
  if (!regex.hasMatch(emailDigitado.trim())) return 'Email inválido';
  return null;
}

String? validarTelefone(String? telefoneDigitado) {
  if (telefoneDigitado == null || telefoneDigitado.trim().isEmpty) {
    return 'Preencha o telefone';
  }
  final digitos = telefoneDigitado.replaceAll(RegExp(r'\D'), '');
  if (digitos.length < 10 || digitos.length > 11) {
    return 'Telefone deve ter 10 ou 11 dígitos';
  }
  return null;
}

String? validarCpfCnpj(String? cpfcnpjDigitado) {
  if (cpfcnpjDigitado == null || cpfcnpjDigitado.trim().isEmpty) {
    return 'Preencha o CPF ou CNPJ';
  }
  final digitos = cpfcnpjDigitado.replaceAll(RegExp(r'\D'), '');
  if (digitos.length == 11) {
    if (!validarCpf(digitos)) return 'CPF inválido';
  } else if (digitos.length == 14) {
    if (!validarCnpj(digitos)) return 'CNPJ inválido';
  } else {
    return 'Digite um CPF (11 dígitos) ou CNPJ (14 dígitos)';
  }
  return null;
}

bool validarCnpj(String cnpj) {
  if (cnpj.length != 14 || cnpj == cnpj[0] * 14) return false;
  final pesosPrimeiroDigito = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  final pesosSegundoDigito = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  for (final regra in [(pesosPrimeiroDigito, 12), (pesosSegundoDigito, 13)]) {
    final pesos = regra.$1;
    final posicaoDoVerificador = regra.$2;
    int soma = 0;
    for (int posicao = 0; posicao < posicaoDoVerificador; posicao++) {
      soma += int.parse(cnpj[posicao]) * pesos[posicao];
    }
    final resto = soma % 11;
    final digito = resto < 2 ? 0 : 11 - resto;
    if (digito != int.parse(cnpj[posicaoDoVerificador])) return false;
  }
  return true;
}
