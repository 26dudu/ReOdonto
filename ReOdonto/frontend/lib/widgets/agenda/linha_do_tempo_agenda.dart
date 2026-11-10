import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../theme/app_colors.dart';
import 'cartao_consulta.dart';

class LinhaDoTempoAgenda extends StatelessWidget {
  final List<Agendamento> itens;
  final ValueChanged<Agendamento> onConfirmar;
  final ValueChanged<Agendamento> onCancelar;
  final ValueChanged<Agendamento> onAgendar;

  const LinhaDoTempoAgenda({
    super.key,
    required this.itens,
    required this.onConfirmar,
    required this.onCancelar,
    required this.onAgendar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int posicao = 0; posicao < itens.length; posicao++)
          _ItemLinhaDoTempo(
            agendamento: itens[posicao],
            ultimo: posicao == itens.length - 1,
            onConfirmar: () => onConfirmar(itens[posicao]),
            onCancelar: () => onCancelar(itens[posicao]),
            onAgendar: () => onAgendar(itens[posicao]),
          ),
      ],
    );
  }
}

class _ItemLinhaDoTempo extends StatelessWidget {
  final Agendamento agendamento;
  final bool ultimo;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;
  final VoidCallback onAgendar;

  const _ItemLinhaDoTempo({
    required this.agendamento,
    required this.ultimo,
    required this.onConfirmar,
    required this.onCancelar,
    required this.onAgendar,
  });

  @override
  Widget build(BuildContext context) {
    final vago = agendamento.vago;
    final Color corPonto = vago
        ? Colors.white
        : (agendamento.concluido ? AppColors.confirmado : AppColors.pendente);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                agendamento.horario,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textoEscuro,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: corPonto,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: vago ? AppColors.azulClaro : corPonto,
                      width: 2,
                    ),
                  ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(width: 2, color: AppColors.bordaCampo),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CartaoConsulta(
                consulta: agendamento,
                onConfirmar: onConfirmar,
                onCancelar: onCancelar,
                onAgendar: onAgendar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
