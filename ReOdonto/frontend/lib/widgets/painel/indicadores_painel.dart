import 'package:flutter/material.dart';
import '../../../../../../../models/resumo_painel.dart';
import '../../../../../../../theme/app_colors.dart';
import 'cartao_indicador.dart';
import 'grafico_desempenho.dart' show formatarReaisInteiro;

// NOVO WIDGET: os 4 cartões do topo do painel (prejuízo evitado, ociosidade,
// horários recuperados e pacientes encaixados) eram montados dentro do
// _conteudo da telaMenu.dart, junto com o for/if do layout desktop.

/// Os 4 cartões de indicadores: empilhados no celular, lado a lado no desktop.
class IndicadoresPainel extends StatelessWidget {
  final ResumoPainel resumo;
  final bool celular;

  const IndicadoresPainel({
    super.key,
    required this.resumo,
    required this.celular,
  });

  @override
  Widget build(BuildContext context) {
    final indicadores = [
      CartaoIndicador(
        icone: Icons.attach_money,
        corIcone: AppColors.painelTealTexto,
        titulo: 'Prejuízo evitado',
        valor: formatarReaisInteiro(resumo.prejuizoEvitado),
      ),
      CartaoIndicador(
        icone: Icons.pie_chart_outline,
        corIcone: AppColors.painelRoxo,
        titulo: 'Ociosidade',
        valor: '${resumo.ociosidade.round()}%',
      ),
      CartaoIndicador(
        icone: Icons.calendar_today_outlined,
        corIcone: AppColors.azulPrimario,
        titulo: 'Horários recuperados',
        valor: '${resumo.horariosRecuperados}',
      ),
      CartaoIndicador(
        icone: Icons.group_outlined,
        corIcone: AppColors.confirmadoTexto,
        titulo: 'Pacientes encaixados',
        valor: '${resumo.pacientesEncaixados}',
      ),
    ];

    // Celular: um cartão embaixo do outro, com 14 px entre eles.
    if (celular) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final cartao in indicadores) ...[
            cartao,
            const SizedBox(height: 14),
          ],
        ],
      );
    }

    // Desktop: os 4 cartões na mesma linha, todos com a mesma altura.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //Volta 1 (posicao = 0): o if (posicao > 0) é falso, então não coloca espaço. Coloca indicadores[0], o cartão de Prejuízo evitado.
          //Volta 2 (posicao = 1): o if é verdadeiro, então coloca o espaço de 14 px. Depois coloca indicadores[1], o cartão de Ociosidade.
          //Volta 3 (posicao = 2): espaço de 14 px, depois indicadores[2], o de Horários recuperados.
          //Volta 4 (posicao = 3): espaço de 14 px, depois indicadores[3], o de Pacientes encaixados.
          //Fim: a posicao vira 4, e 4 < indicadores.length (que é 4) é falso, então o for para.
          for (int posicao = 0; posicao < indicadores.length; posicao++) ...[
            if (posicao > 0) const SizedBox(width: 14),
            Expanded(child: indicadores[posicao]),
          ],
        ],
      ),
    );
  }
}
