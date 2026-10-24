import 'package:flutter/material.dart';

/// Mostra um SnackBar. Um único lugar para o aviso do app inteiro:
/// - [erro]    → fundo vermelho
/// - [sucesso] → fundo verde
/// - nenhum    → aviso neutro (cor padrão do tema)
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
