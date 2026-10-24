import 'package:flutter/services.dart';

/// Formata automaticamente CPF (000.000.000-00) ou CNPJ (00.000.000/0000-00)
/// dependendo da quantidade de dígitos digitados.
/// Até 11 dígitos → CPF. 12+ dígitos → CNPJ.
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extrai somente dígitos
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limita a 14 dígitos
    final limitado = digitos.length > 14 ? digitos.substring(0, 14) : digitos;

    final formatado = limitado.length <= 11
        ? _formatarCpf(limitado)
        : _formatarCnpj(limitado);

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }

  String _formatarCpf(String digitados) {
    // 000.000.000-00
    final cpf = StringBuffer();
    for (int posicao = 0; posicao < digitados.length; posicao++) {
      if (posicao == 3 || posicao == 6) cpf.write('.');
      if (posicao == 9) cpf.write('-');
      cpf.write(digitados[posicao]);
    }
    return cpf.toString();
  }

  String _formatarCnpj(String digitos) {
    // 00.000.000/0000-00
    final cnpj = StringBuffer();
    for (int posicao = 0; posicao < digitos.length; posicao++) {
      if (posicao == 2 || posicao == 5) cnpj.write('.');
      if (posicao == 8) cnpj.write('/');
      if (posicao == 12) cnpj.write('-');
      cnpj.write(digitos[posicao]);
    }
    return cnpj.toString();
  }
}

/// Máscara de telefone: (00) 00000-0000 ou (00) 0000-0000
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
    final formatado = _formatar(limitado);

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }

  String _formatar(String digitos) {
    final telefone = StringBuffer();
    for (int posicao = 0; posicao < digitos.length; posicao++) {
      if (posicao == 0) telefone.write('(');
      if (posicao == 2) telefone.write(') ');
      // Celular (11 dígitos): quebra no 7º dígito
      // Fixo  (10 dígitos): quebra no 6º dígito
      final quebra = digitos.length == 11 ? 7 : 6;
      if (posicao == quebra) telefone.write('-');
      telefone.write(digitos[posicao]);
    }
    return telefone.toString();
  }
}

/// Máscara CRO: apenas letras e dígitos, ex: SP-12345
class CroInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permite letras, números e hífen; maiúsculas; limita a 10 chars
    final texto = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9\-]'),
      '',
    );
    final limitado = texto.length > 10 ? texto.substring(0, 10) : texto;
    return TextEditingValue(
      text: limitado,
      selection: TextSelection.collapsed(offset: limitado.length),
    );
  }
}
