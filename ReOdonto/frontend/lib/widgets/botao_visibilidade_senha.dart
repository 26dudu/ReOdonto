import 'package:flutter/material.dart';

// NOVO WIDGET: o "olhinho" que mostra/esconde a senha estava escrito à mão em
// 4 lugares (login, nova senha e 2x no cadastro). Agora é um widget só.

/// Botão de olho para alternar entre senha oculta e visível.
class BotaoVisibilidadeSenha extends StatelessWidget {
  /// true = senha escondida (mostra o olho riscado).
  final bool oculta;

  /// Chamado ao tocar. Passe null para desabilitar (ex.: durante o carregamento).
  final VoidCallback? onPressed;

  /// Cor do ícone (null = cor padrão do tema).
  final Color? cor;

  const BotaoVisibilidadeSenha({
    super.key,
    required this.oculta,
    required this.onPressed,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        oculta ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: cor,
      ),
      onPressed: onPressed,
    );
  }
}
