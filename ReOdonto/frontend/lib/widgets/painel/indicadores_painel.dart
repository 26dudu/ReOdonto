import 'package:flutter/material.dart';
import '../../../../../../../models/resumo_painel.dart';
import '../../../../../../../theme/app_colors.dart';
import 'cartao_indicador.dart';
import 'grafico_desempenho.dart' show formatarReaisInteiro;

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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int posicao = 0; posicao < indicadores.length; posicao++) ...[
            if (posicao > 0) const SizedBox(width: 14),
            Expanded(child: indicadores[posicao]),
          ],
        ],
      ),
    );
  }
}
