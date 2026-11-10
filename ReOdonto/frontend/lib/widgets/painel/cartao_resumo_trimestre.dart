import 'package:flutter/material.dart';
import '../../models/resumo_painel.dart';
import '../../theme/app_colors.dart';
import 'cartao_indicador.dart';

class LinhaResumoTrimestre {
  final IconData icone;
  final String rotulo;
  final String valor;

  const LinhaResumoTrimestre({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });
}

class CartaoResumoTrimestre extends StatelessWidget {
  final List<LinhaResumoTrimestre> linhas;
  const CartaoResumoTrimestre({super.key, required this.linhas});

  factory CartaoResumoTrimestre.deResumo(ResumoPainel resumo) {
    return CartaoResumoTrimestre(
      linhas: [
        LinhaResumoTrimestre(
          icone: Icons.event_available_outlined,
          rotulo: 'Consultas realizadas',
          valor: '${resumo.consultasRealizadas}',
        ),
        LinhaResumoTrimestre(
          icone: Icons.cancel_outlined,
          rotulo: 'Cancelamentos',
          valor: '${resumo.cancelamentos}',
        ),
        LinhaResumoTrimestre(
          icone: Icons.event_repeat_outlined,
          rotulo: 'Horários recuperados',
          valor: '${resumo.horariosRecuperados3Meses}',
        ),
        LinhaResumoTrimestre(
          icone: Icons.bar_chart,
          rotulo: 'Taxa de ocupação',
          valor: '${resumo.taxaOcupacao.round()}%',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo dos últimos 3 meses',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.fundoCartao,
            borderRadius: BorderRadius.circular(20),
            boxShadow: sombraCartaoPainel,
          ),
          child: Column(
            children: [
              for (int posicao = 0; posicao < linhas.length; posicao++) ...[
                if (posicao > 0) const SizedBox(height: 10),
                _Linha(linha: linhas[posicao]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  final LinhaResumoTrimestre linha;
  const _Linha({required this.linha});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(linha.icone, size: 17, color: AppColors.azulClaro),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            linha.rotulo,
            style: const TextStyle(fontSize: 13, color: AppColors.textoEscuro),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          linha.valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textoEscuro,
          ),
        ),
      ],
    );
  }
}
