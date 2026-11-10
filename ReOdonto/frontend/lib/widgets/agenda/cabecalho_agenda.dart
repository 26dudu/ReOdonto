import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';

class CabecalhoAgenda extends StatelessWidget {
  final String? nomeDentista;

  const CabecalhoAgenda({super.key, required this.nomeDentista});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sua agenda',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textoEscuro,
            ),
            children: [
              const TextSpan(text: 'Olá, Dra. '),
              TextSpan(
                text: nomeDentista ?? 'Dentista',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulPrimario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
