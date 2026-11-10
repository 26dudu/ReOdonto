import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class IndicadorProgresso extends StatelessWidget {
  final int etapaAtual;
  final int totalEtapas;

  const IndicadorProgresso({
    super.key,
    required this.etapaAtual,
    this.totalEtapas = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalEtapas, (posicao) {
        final ativo = posicao == etapaAtual;
        final concluido = posicao < etapaAtual;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: concluido
                  ? Colors.green
                  : ativo
                  ? AppColors.azulPrimario
                  : AppColors.bordaCampo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
