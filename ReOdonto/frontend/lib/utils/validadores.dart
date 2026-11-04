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

// =============================================================================
// MOVIDO DE pages/telaCadastro.dart: antes estes validadores (nome, e-mail,
// telefone, CPF/CNPJ) ficavam dentro da tela, ocupando ~100 linhas. Agora
// ficam aqui junto dos outros validadores e a tela só os referencia.
// O CPF NÃO foi duplicado: usa o `validarCpf` que já existia neste arquivo.
// =============================================================================

/// Validator do nome: devolve mensagem de erro (String) ou null se estiver ok.
String? validarNome(String? nomeDigitado) {
  // Vazio (ou só espaços).
  if (nomeDigitado == null || nomeDigitado.trim().isEmpty) {
    return 'Preencha o nome completo';
  }
  // Muito curto.
  if (nomeDigitado.trim().length < 3) {
    return 'Nome deve ter pelo menos 3 caracteres';
  }
  return null;
}

/// Validator do e-mail.
String? validarEmail(String? emailDigitado) {
  if (emailDigitado == null || emailDigitado.trim().isEmpty) {
    return 'Preencha o email';
  }
  // Expressão regular: texto@dominio.xx (letras, números, ponto, + e - antes do @).
  final regex = RegExp(
    r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$',
    // Ignora maiúsculas/minúsculas.
    caseSensitive: false,
  );
  // Se o texto não bater com a regra, dá erro.
  if (!regex.hasMatch(emailDigitado.trim())) return 'Email inválido';
  return null;
}

/// Validator do telefone (10 dígitos = fixo, 11 = celular).
String? validarTelefone(String? telefoneDigitado) {
  if (telefoneDigitado == null || telefoneDigitado.trim().isEmpty) {
    return 'Preencha o telefone';
  }
  // Remove tudo que não é dígito (parênteses, espaço, hífen).
  final digitos = telefoneDigitado.replaceAll(RegExp(r'\D'), '');
  if (digitos.length < 10 || digitos.length > 11) {
    return 'Telefone deve ter 10 ou 11 dígitos';
  }
  return null;
}

/// Validator do CPF/CNPJ: decide pelo tamanho qual algoritmo usar.
String? validarCpfCnpj(String? cpfcnpjDigitado) {
  if (cpfcnpjDigitado == null || cpfcnpjDigitado.trim().isEmpty) {
    return 'Preencha o CPF ou CNPJ';
  }
  // Só os números.
  final digitos = cpfcnpjDigitado.replaceAll(RegExp(r'\D'), '');
  if (digitos.length == 11) {
    // 11 dígitos = CPF.
    if (!validarCpf(digitos)) return 'CPF inválido';
  } else if (digitos.length == 14) {
    // 14 dígitos = CNPJ.
    if (!validarCnpj(digitos)) return 'CNPJ inválido';
  } else {
    // Qualquer outro tamanho é inválido.
    return 'Digite um CPF (11 dígitos) ou CNPJ (14 dígitos)';
  }
  return null;
}

/// Confere os dígitos verificadores de um CNPJ (recebe só números).
bool validarCnpj(String cnpj) {
  // Rejeita tamanho errado e dígitos todos iguais.
  if (cnpj.length != 14 || cnpj == cnpj[0] * 14) return false;
  // Pesos oficiais para o 1º dígito verificador (12 números).
  final pesosPrimeiroDigito = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  // Pesos oficiais para o 2º dígito verificador (13 números).
  final pesosSegundoDigito = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  // Itera sobre pares (pesos, posição do dígito). "Record" do Dart 3.
  for (final regra in [(pesosPrimeiroDigito, 12), (pesosSegundoDigito, 13)]) {
    // $1 = primeiro item do par (lista de pesos).
    final pesos = regra.$1;
    // $2 = segundo item do par (posição do dígito verificador).
    final posicaoDoVerificador = regra.$2;
    int soma = 0;
    for (int posicao = 0; posicao < posicaoDoVerificador; posicao++) {
      // Dígito × peso correspondente.
      soma += int.parse(cnpj[posicao]) * pesos[posicao];
    }
    // Resto da divisão por 11.
    final resto = soma % 11;
    // Regra: resto menor que 2 → dígito 0; senão 11 - resto.
    final digito = resto < 2 ? 0 : 11 - resto;
    // Compara com o dígito real do CNPJ.
    if (digito != int.parse(cnpj[posicaoDoVerificador])) return false;
  }
  return true;
}
