import 'package:flutter/services.dart';

class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');

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
    final cpf = StringBuffer();
    for (int posicao = 0; posicao < digitados.length; posicao++) {
      if (posicao == 3 || posicao == 6) cpf.write('.');
      if (posicao == 9) cpf.write('-');
      cpf.write(digitados[posicao]);
    }
    return cpf.toString();
  }

  String _formatarCnpj(String digitos) {
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
      final quebra = digitos.length == 11 ? 7 : 6;
      if (posicao == quebra) telefone.write('-');
      telefone.write(digitos[posicao]);
    }
    return telefone.toString();
  }
}

class CroInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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
