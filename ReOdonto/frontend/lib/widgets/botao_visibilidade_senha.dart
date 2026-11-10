import 'package:flutter/material.dart';

class BotaoVisibilidadeSenha extends StatelessWidget {
  final bool oculta;

  final VoidCallback? onPressed;

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
