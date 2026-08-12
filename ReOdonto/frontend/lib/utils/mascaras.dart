import 'package:flutter/services.dart';


class MascaraTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitos.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (digitos.length == 11 && i == 7) buffer.write('-');
      if (digitos.length <= 10 && i == 6) buffer.write('-');
      buffer.write(digitos[i]);
    }

    final formatado = buffer.toString();
    return newValue.copyWith(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}

class MascaraCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitos.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digitos[i]);
    }

    final formatado = buffer.toString();
    return newValue.copyWith(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}


class MascaraCep extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitos.length && i < 8; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(digitos[i]);
    }

    final formatado = buffer.toString();
    return newValue.copyWith(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}
