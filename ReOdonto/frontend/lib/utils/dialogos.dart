import 'package:flutter/material.dart';

// NOVO UTIL: a telaAgenda (cancelar consulta) e a telaPerfil (sair da conta)
// montavam, cada uma, um AlertDialog de "tem certeza?" com 2 botões.
// Agora as duas chamam `confirmarAcao`.

/// Mostra um pop-up de confirmação com dois botões.
/// Devolve true se o usuário confirmou; false/null se voltou ou cancelou.
Future<bool?> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String textoConfirmar,
  required String textoVoltar,
  // Cor do botão de confirmar (ex.: vermelho para ações destrutivas).
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
