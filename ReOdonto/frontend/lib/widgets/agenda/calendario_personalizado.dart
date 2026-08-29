import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CalendarioPersonalizado extends StatefulWidget {
  final DateTime dataInicial;
  final DateTime dataFinal;
  final DateTime? dataSelecionada;
  final ValueChanged<DateTime> onDataSelecionada;

  const CalendarioPersonalizado({
    super.key,
    required this.dataInicial,
    required this.dataFinal,
    this.dataSelecionada,
    required this.onDataSelecionada,
  });

  @override
  State<CalendarioPersonalizado> createState() => _CalendarioPersonalizadoState();
}

class _CalendarioPersonalizadoState extends State<CalendarioPersonalizado> {
  late DateTime _mesAtual;

  @override
  void initState() {
    super.initState();
    _mesAtual = widget.dataSelecionada ?? widget.dataInicial;
  }

  void _mesAnterior() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1);
      if (_mesAtual.isBefore(widget.dataInicial)) {
        _mesAtual = widget.dataInicial;
      }
    });
  }

  void _proximoMes() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1);
      if (_mesAtual.isAfter(DateTime(widget.dataFinal.year, widget.dataFinal.month + 1))) {
        _mesAtual = DateTime(widget.dataFinal.year, widget.dataFinal.month);
      }
    });
  }

  bool _podeIrAnterior() {
    return !_mesAtual.isAtSameMomentAs(DateTime(widget.dataInicial.year, widget.dataInicial.month));
  }

  bool _podeIrProximo() {
    final proximoMes = DateTime(_mesAtual.year, _mesAtual.month + 1);
    return proximoMes.isBefore(widget.dataFinal) || 
           proximoMes.isAtSameMomentAs(DateTime(widget.dataFinal.year, widget.dataFinal.month));
  }

  List<DateTime> _obterDiasDoMes(int year, int month) {
    final primeiro = DateTime(year, month, 1);
    final ultimo = DateTime(year, month + 1, 0);
    final dias = <DateTime>[];

    // Adiciona dias em branco do mês anterior
    for (int i = primeiro.weekday - 1; i > 0; i--) {
      dias.add(primeiro.subtract(Duration(days: i)));
    }

    // Adiciona todos os dias do mês
    for (int i = 1; i <= ultimo.day; i++) {
      dias.add(DateTime(year, month, i));
    }

    // Completa com dias do próximo mês se necessário
    final diasFaltantes = 42 - dias.length; // 6 linhas × 7 dias
    for (int i = 1; i <= diasFaltantes; i++) {
      dias.add(ultimo.add(Duration(days: i)));
    }

    return dias;
  }

  bool _estahDesabilitado(DateTime dia) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final diaSemHora = DateTime(dia.year, dia.month, dia.day);

    // Desabilita datas no passado e fora do intervalo permitido
    if (diaSemHora.isBefore(hojeSemHora)) return true;
    if (diaSemHora.isBefore(widget.dataInicial)) return true;
    if (diaSemHora.isAfter(widget.dataFinal)) return true;

    return false;
  }

  bool _pertenceAoMes(DateTime dia) {
    return dia.year == _mesAtual.year && dia.month == _mesAtual.month;
  }

  @override
  Widget build(BuildContext context) {
    final diasDoMes = _obterDiasDoMes(_mesAtual.year, _mesAtual.month);
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    return Column(
      children: [
        // ---- Cabeçalho com navegação de meses ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _podeIrAnterior() ? _mesAnterior : null,
                icon: const Icon(Icons.chevron_left),
                color: _podeIrAnterior() ? AppColors.azulPrimario : AppColors.bordaCampo,
              ),
              Text(
                _obterNomeMes(_mesAtual.month, _mesAtual.year),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoEscuro,
                ),
              ),
              IconButton(
                onPressed: _podeIrProximo() ? _proximoMes : null,
                icon: const Icon(Icons.chevron_right),
                color: _podeIrProximo() ? AppColors.azulPrimario : AppColors.bordaCampo,
              ),
            ],
          ),
        ),

        // ---- Cabeçalho com dias da semana ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _DiaSemanaCabecalho('Dom'),
              _DiaSemanaCabecalho('Seg'),
              _DiaSemanaCabecalho('Ter'),
              _DiaSemanaCabecalho('Qua'),
              _DiaSemanaCabecalho('Qui'),
              _DiaSemanaCabecalho('Sex'),
              _DiaSemanaCabecalho('Sab'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ---- Grade de dias ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: diasDoMes.length,
            itemBuilder: (context, index) {
              final dia = diasDoMes[index];
              final pertenceAoMes = _pertenceAoMes(dia);
              final estahDesabilitado = _estahDesabilitado(dia);
              final diaSemHora = DateTime(dia.year, dia.month, dia.day);
              final estahSelecionado = widget.dataSelecionada != null &&
                  diaSemHora.isAtSameMomentAs(
                    DateTime(
                      widget.dataSelecionada!.year,
                      widget.dataSelecionada!.month,
                      widget.dataSelecionada!.day,
                    ),
                  );
              final ehHoje = diaSemHora.isAtSameMomentAs(hojeSemHora);

              return GestureDetector(
                onTap: !pertenceAoMes || estahDesabilitado
                    ? null
                    : () => widget.onDataSelecionada(dia),
                child: Container(
                  decoration: BoxDecoration(
                    color: estahSelecionado
                        ? AppColors.azulPrimario
                        : ehHoje
                            ? AppColors.azulClaro.withValues(alpha: 0.2)
                            : Colors.transparent,
                    border: Border.all(
                      color: ehHoje ? AppColors.azulClaro : Colors.transparent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      dia.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: estahSelecionado || ehHoje ? FontWeight.w600 : FontWeight.normal,
                        color: estahSelecionado
                            ? Colors.white
                            : !pertenceAoMes || estahDesabilitado
                                ? AppColors.bordaCampo
                                : AppColors.textoEscuro,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _obterNomeMes(int mes, int ano) {
    const nomes = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${nomes[mes - 1]} de $ano';
  }
}

class _DiaSemanaCabecalho extends StatelessWidget {
  final String dia;

  const _DiaSemanaCabecalho(this.dia);

  @override
  Widget build(BuildContext context) {
    return Text(
      dia,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textoCinza,
      ),
    );
  }
}
