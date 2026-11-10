import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';

class SaudacaoPainel extends StatelessWidget {
  final String primeiroNome;

  const SaudacaoPainel({super.key, required this.primeiroNome});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textoEscuro,
        ),
        children: [
          const TextSpan(text: 'Olá, Dr(a). '),
          TextSpan(
            text: primeiroNome,
            style: const TextStyle(color: AppColors.azulPrimario),
          ),
        ],
      ),
    );
  }
}
