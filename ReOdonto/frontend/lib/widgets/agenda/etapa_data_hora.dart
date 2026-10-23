import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatadores.dart';
import 'cartao_resumo.dart';
import 'calendario_personalizado.dart';
import 'input_horario.dart';


// Mostra um resumo do que foi preenchido nas etapas anteriores, um calendário para escolher a data e um seletor de horário.

class EtapaDataHora extends StatelessWidget {
  final String nomePaciente;
  final String tipoConsulta;
  final DateTime? dataSelecionada;
  final TimeOfDay? horarioSelecionado;
  final ValueChanged<DateTime> onDataSelecionada;
  final ValueChanged<TimeOfDay> onHorarioSelecionado;

  const EtapaDataHora({
    super.key,
    required this.nomePaciente,
    required this.tipoConsulta,
    required this.dataSelecionada,
    required this.horarioSelecionado,
    required this.onDataSelecionada,
    required this.onHorarioSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    String dataFormatada = 'Nenhuma data selecionada';
    if (dataSelecionada != null && horarioSelecionado != null) {
      dataFormatada =
          formatarDataEHora(dataSelecionada!, horarioSelecionado!);
    }

    final agora = DateTime.now();
    final dataFinal = agora.add(const Duration(days: 365));
    final dataHoraCompleta = dataSelecionada != null && horarioSelecionado != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CartaoResumo(
            paciente: nomePaciente,
            consulta: tipoConsulta,
          ),
          const SizedBox(height: 24),
          CalendarioPersonalizado(
            dataInicial: agora.add(const Duration(days: 1)),
            dataFinal: dataFinal,
            dataSelecionada: dataSelecionada,
            onDataSelecionada: onDataSelecionada,
          ),
          const SizedBox(height: 24),
          InputHorario(
            horarioSelecionado: horarioSelecionado,
            onHorarioSelecionado: onHorarioSelecionado,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dataHoraCompleta
                  ? AppColors.azulClaro.withValues(alpha: 0.1)
                  : AppColors.bordaCampo.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dataFormatada,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: dataHoraCompleta
                    ? AppColors.azulPrimario
                    : AppColors.textoCinza,
              ),
            ),
          ),
        ],
      ),
    );
  }
}