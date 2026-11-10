import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';

class IndicadorEtapa extends StatelessWidget {
  final int etapaAtual;

  final int totalEtapas;

  const IndicadorEtapa({
    super.key,
    required this.etapaAtual,
    this.totalEtapas = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalEtapas, (posicao) {
        final ativa = posicao == etapaAtual;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: ativa ? 22 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: ativa ? AppColors.azulPrimario : const Color(0xFFCBD5E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
