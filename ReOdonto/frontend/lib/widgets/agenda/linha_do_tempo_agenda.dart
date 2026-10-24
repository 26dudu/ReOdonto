import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../theme/app_colors.dart';
import 'cartao_consulta.dart';


// Mostra o dia como uma LINHA DO TEMPO: horário à esquerda, uma linha vertical
// com bolinhas no meio e o cartão da consulta à direita.
//
// Consultas marcadas e horários vagos ficam JUNTOS, em ordem de horário, então
// o dentista enxerga os "buracos" do dia de relance.
//
// Cor da bolinha:
//   • verde  = consulta confirmada
//   • laranja = consulta pendente
//   • vazada (borda azul clara) = horário vago
//
// A lista `itens` já deve chegar ORDENADA por horário (a telaAgenda faz isso).


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

/// Uma linha da linha do tempo: [horário] [bolinha+traço] [cartão].
class _ItemLinhaDoTempo extends StatelessWidget {
  final Agendamento agendamento;
  final bool ultimo; // o último item não desenha o traço para baixo
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
        : (agendamento.status == 'Confirmado'
            ? AppColors.confirmado
            : AppColors.pendente);

    // IntrinsicHeight faz o traço vertical esticar até a altura do cartão.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Coluna 1: horário ------------------------------------------------
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

          // ---- Coluna 2: bolinha + traço vertical ---------------------------------
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

          // ---- Coluna 3: cartão ---------------------------------------------------
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
