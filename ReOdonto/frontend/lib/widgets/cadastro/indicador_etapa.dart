import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';

// NOVO WIDGET: este indicador (as 2 barrinhas "etapa 1 de 2") estava copiado e
// colado como `_IndicadorEtapa` dentro de telaCadastro.dart E de
// telaSenhaCadastro.dart. Agora existe uma única vez, aqui.

/// Barrinhas do topo do cadastro. A da etapa atual fica mais larga e azul.
class IndicadorEtapa extends StatelessWidget {
  /// Índice da etapa ativa (0 = dados pessoais, 1 = senha).
  final int etapaAtual;

  /// Quantas barrinhas desenhar (o cadastro tem 2 etapas).
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
        // Barrinha ativa = a da etapa atual.
        final ativa = posicao == etapaAtual;
        // Container animado: muda largura e cor suavemente.
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
