import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// Mostra os tracinhos horizontais no topo do modal
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
      // RENOMEADO: 'i' agora é 'posicao' (posição da barrinha (0, 1, 2...)).
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
