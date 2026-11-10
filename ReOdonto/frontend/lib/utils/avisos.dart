import 'package:flutter/material.dart';

void mostrarAviso(
  BuildContext context,
  String mensagem, {
  bool erro = false,
  bool sucesso = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensagem),
      backgroundColor: erro
          ? Colors.redAccent
          : sucesso
              ? Colors.green
              : null,
    ),
  );
}
