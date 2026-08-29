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

  String _formatarCpf(String d) {
    // 000.000.000-00
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) b.write('.');
      if (i == 9) b.write('-');
      b.write(d[i]);
    }
    return b.toString();
  }

  String _formatarCnpj(String d) {
    // 00.000.000/0000-00
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i == 2 || i == 5) b.write('.');
      if (i == 8) b.write('/');
      if (i == 12) b.write('-');
      b.write(d[i]);
    }
    return b.toString();
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

  String _formatar(String d) {
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      // Celular (11 dígitos): quebra no 7º dígito
      // Fixo  (10 dígitos): quebra no 6º dígito
      final quebra = d.length == 11 ? 7 : 6;
      if (i == quebra) b.write('-');
      b.write(d[i]);
    }
    return b.toString();
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
    final texto = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
    final limitado = texto.length > 10 ? texto.substring(0, 10) : texto;
    return TextEditingValue(
      text: limitado,
      selection: TextSelection.collapsed(offset: limitado.length),
    );
  }
}
