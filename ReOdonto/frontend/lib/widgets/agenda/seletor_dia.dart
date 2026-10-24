import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatadores.dart';

// =============================================================================
// Barra para escolher QUAL DIA da agenda está sendo visto.
//
// O que ela tem:
//  • Setas < e > para ir ao dia anterior / seguinte.
//  • Título com o dia por extenso ("Segunda-feira, 28 de setembro"). Tocar
//    nele abre o calendário nativo (showDatePicker) — em pt-BR, graças ao
//    flutter_localizations configurado no main.dart.
//  • Faixa semanal (Seg–Dom) com uma bolinha nos dias que têm consulta.
//  • Botão "Voltar para hoje" (aparece só quando você não está em hoje).
//
// É um widget "burro": não guarda o dia. Quem guarda é a telaAgenda; este
// widget só avisa via `onDiaSelecionado` quando o usuário escolhe outro.
// =============================================================================
class SeletorDia extends StatelessWidget {
  /// Dia atualmente exibido (só data, sem hora).
  final DateTime diaSelecionado;

  /// Dias que têm pelo menos uma consulta marcada (recebem a bolinha).
  /// Cada item deve estar "zerado" (sem hora) — veja apenasData().
  final Set<DateTime> diasComConsulta;

  final ValueChanged<DateTime> onDiaSelecionado;

  const SeletorDia({
    super.key,
    required this.diaSelecionado,
    required this.diasComConsulta,
    required this.onDiaSelecionado,
  });

  /// Soma (ou subtrai) dias usando o construtor DateTime(y, m, d + n), que
  /// resolve virada de mês/ano sozinho e não sofre com horário de verão.
  DateTime _somarDias(DateTime base, int dias) =>
      DateTime(base.year, base.month, base.day + dias);

  Future<void> _abrirCalendario(BuildContext context) async {
    final hoje = apenasData(DateTime.now());
    var primeiro = DateTime(hoje.year - 2);
    var ultimo = DateTime(hoje.year + 2, 12, 31);
    // O showDatePicker exige que initialDate esteja entre first e last.
    if (diaSelecionado.isBefore(primeiro)) primeiro = diaSelecionado;
    if (diaSelecionado.isAfter(ultimo)) ultimo = diaSelecionado;

    final escolhido = await showDatePicker(
      context: context,
      initialDate: diaSelecionado,
      firstDate: primeiro,
      lastDate: ultimo,
      helpText: 'Selecione o dia',
    );
    if (escolhido != null) onDiaSelecionado(apenasData(escolhido));
  }

  @override
  Widget build(BuildContext context) {
    // weekday: 1 = segunda ... 7 = domingo. Voltamos até a segunda-feira da
    // semana do dia selecionado e geramos os 7 dias a partir dela.
    final segunda = _somarDias(diaSelecionado, -(diaSelecionado.weekday - 1));
    final semana = List.generate(7, (i) => _somarDias(segunda, i));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fundoCartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordaCampo),
      ),
      child: Column(
        children: [
          // ---- Linha das setas + título do dia --------------------------------
          Row(
            children: [
              IconButton(
                tooltip: 'Dia anterior',
                onPressed: () => onDiaSelecionado(_somarDias(diaSelecionado, -1)),
                icon: const Icon(Icons.chevron_left, color: AppColors.textoEscuro),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _abrirCalendario(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Text(
                          formatarDiaExtenso(diaSelecionado),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textoEscuro,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month_outlined,
                                size: 14, color: AppColors.azulPrimario),
                            SizedBox(width: 4),
                            Text(
                              'Toque para escolher a data',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.azulPrimario,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Próximo dia',
                onPressed: () => onDiaSelecionado(_somarDias(diaSelecionado, 1)),
                icon: const Icon(Icons.chevron_right, color: AppColors.textoEscuro),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ---- Faixa semanal ---------------------------------------------------
          Row(
            children: [
              for (final dia in semana)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DiaDaSemana(
                      dia: dia,
                      selecionado: mesmoDia(dia, diaSelecionado),
                      temConsulta: diasComConsulta.contains(apenasData(dia)),
                      onTap: () => onDiaSelecionado(apenasData(dia)),
                    ),
                  ),
                ),
            ],
          ),

          // ---- Atalho para hoje (some quando já estamos em hoje) --------------
          if (!ehHoje(diaSelecionado))
            TextButton.icon(
              onPressed: () => onDiaSelecionado(apenasData(DateTime.now())),
              icon: const Icon(Icons.today, size: 16),
              label: const Text('Voltar para hoje'),
            ),
        ],
      ),
    );
  }
}

/// Um "botãozinho" da faixa semanal: dia da semana, número e bolinha.
class _DiaDaSemana extends StatelessWidget {
  final DateTime dia;
  final bool selecionado;
  final bool temConsulta;
  final VoidCallback onTap;

  const _DiaDaSemana({
    required this.dia,
    required this.selecionado,
    required this.temConsulta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hoje = ehHoje(dia);
    final corTexto = selecionado ? Colors.white : AppColors.textoEscuro;

    return Material(
      color: selecionado ? AppColors.azulPrimario : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatarDiaSemanaAbreviado(dia),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selecionado ? Colors.white : AppColors.textoCinza,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${dia.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  // Hoje (quando não selecionado) fica em azul para se destacar.
                  color: (hoje && !selecionado) ? AppColors.azulPrimario : corTexto,
                ),
              ),
              const SizedBox(height: 4),
              // Bolinha: indica que o dia tem consulta marcada.
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: temConsulta
                      ? (selecionado ? Colors.white : AppColors.azulPrimario)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
