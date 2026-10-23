import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TituloSecao extends StatelessWidget {
  final String texto;
  const TituloSecao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textoEscuro,
      ),
    );
  }
}

class TextoVazio extends StatelessWidget {
  final String texto;
  const TextoVazio(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: AppColors.textoCinza,
      ),
    );
  }
}
