import 'package:flutter/material.dart';

Future<bool?> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String textoConfirmar,
  required String textoVoltar,
  Color? corConfirmar,
}) {
  return showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contexto, false),
          child: Text(textoVoltar),
        ),
        TextButton(
          onPressed: () => Navigator.pop(contexto, true),
          child: Text(
            textoConfirmar,
            style: corConfirmar == null ? null : TextStyle(color: corConfirmar),
          ),
        ),
      ],
    ),
  );
}
