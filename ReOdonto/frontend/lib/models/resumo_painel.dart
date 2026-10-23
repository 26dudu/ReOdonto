import 'package:intl/intl.dart';

/// Um mês do gráfico "Desempenho dos últimos meses".
class MesDesempenho {
  final String rotulo; // "Jun", "Jul"...
  final double valor; // prejuízo evitado no mês, em R$

  const MesDesempenho({required this.rotulo, required this.valor});

  factory MesDesempenho.fromJson(Map<String, dynamic> json) => MesDesempenho(
        rotulo: json['mes'] as String? ?? '',
        valor: (json['valor'] as num?)?.toDouble() ?? 0,
      );
}

/// Todos os números do Painel Administrativo (tela "Menu").
///
/// Hoje o app usa [ResumoPainel.vazio] (tudo zerado). Quando o backend Python
/// existir, ele só precisa devolver um JSON neste formato e a tela passa a
/// mostrar os dados reais, sem mudar nenhum widget:
///
/// ```json
/// {
///   "prejuizo_evitado": 8450.0,
///   "ociosidade": 12.0,
///   "horarios_recuperados": 24,
///   "pacientes_encaixados": 21,
///   "resumo_3_meses": {
///     "consultas_realizadas": 84,
///     "cancelamentos": 28,
///     "horarios_recuperados": 24,
///     "taxa_ocupacao": 88.0
///   },
///   "desempenho": [ {"mes": "Jun", "valor": 350.0}, ... ]
/// }
/// ```
class ResumoPainel {
  // Cartões do topo.
  final double prejuizoEvitado;
  final double ociosidade; // percentual (12.0 = 12%)
  final int horariosRecuperados;
  final int pacientesEncaixados;

  // "Resumo dos últimos 3 meses".
  final int consultasRealizadas;
  final int cancelamentos;
  final int horariosRecuperados3Meses;
  final double taxaOcupacao; // percentual

  // Gráfico, do mês mais antigo para o mais recente.
  final List<MesDesempenho> desempenho;

  const ResumoPainel({
    required this.prejuizoEvitado,
    required this.ociosidade,
    required this.horariosRecuperados,
    required this.pacientesEncaixados,
    required this.consultasRealizadas,
    required this.cancelamentos,
    required this.horariosRecuperados3Meses,
    required this.taxaOcupacao,
    required this.desempenho,
  });

  /// Tudo zerado, com os 6 últimos meses já nomeados no gráfico.
  factory ResumoPainel.vazio() => ResumoPainel(
        prejuizoEvitado: 0,
        ociosidade: 0,
        horariosRecuperados: 0,
        pacientesEncaixados: 0,
        consultasRealizadas: 0,
        cancelamentos: 0,
        horariosRecuperados3Meses: 0,
        taxaOcupacao: 0,
        desempenho: _ultimosMeses(6),
      );

  factory ResumoPainel.fromJson(Map<String, dynamic> json) {
    final resumo = (json['resumo_3_meses'] as Map<String, dynamic>?) ?? {};
    final lista = (json['desempenho'] as List?) ?? [];
    return ResumoPainel(
      prejuizoEvitado: (json['prejuizo_evitado'] as num?)?.toDouble() ?? 0,
      ociosidade: (json['ociosidade'] as num?)?.toDouble() ?? 0,
      horariosRecuperados: (json['horarios_recuperados'] as num?)?.toInt() ?? 0,
      pacientesEncaixados: (json['pacientes_encaixados'] as num?)?.toInt() ?? 0,
      consultasRealizadas:
          (resumo['consultas_realizadas'] as num?)?.toInt() ?? 0,
      cancelamentos: (resumo['cancelamentos'] as num?)?.toInt() ?? 0,
      horariosRecuperados3Meses:
          (resumo['horarios_recuperados'] as num?)?.toInt() ?? 0,
      taxaOcupacao: (resumo['taxa_ocupacao'] as num?)?.toDouble() ?? 0,
      desempenho: lista
          .map((e) => MesDesempenho.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// true quando não há nada para mostrar no gráfico.
  bool get graficoVazio => desempenho.every((m) => m.valor <= 0);

  static List<MesDesempenho> _ultimosMeses(int quantidade) {
    final agora = DateTime.now();
    final formato = DateFormat('MMM', 'pt_BR');
    return List.generate(quantidade, (i) {
      final mes = DateTime(agora.year, agora.month - (quantidade - 1 - i));
      final nome = formato.format(mes).replaceAll('.', '');
      return MesDesempenho(
        rotulo: nome[0].toUpperCase() + nome.substring(1),
        valor: 0,
      );
    });
  }
}
