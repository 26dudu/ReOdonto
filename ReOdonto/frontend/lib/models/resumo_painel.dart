import 'package:intl/intl.dart';

class MesDesempenho {
  final String rotulo;
  final double valor;

  const MesDesempenho({required this.rotulo, required this.valor});

  factory MesDesempenho.fromJson(Map<String, dynamic> json) => MesDesempenho(
        rotulo: json['mes'] as String? ?? '',
        valor: (json['valor'] as num?)?.toDouble() ?? 0,
      );
}

class ResumoPainel {
  final double prejuizoEvitado;
  final double ociosidade;
  final int horariosRecuperados;
  final int pacientesEncaixados;

  final int consultasRealizadas;
  final int cancelamentos;
  final int horariosRecuperados3Meses;
  final double taxaOcupacao;

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
          .map((itemJson) => MesDesempenho.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get graficoVazio => desempenho.every((mes) => mes.valor <= 0);

  static List<MesDesempenho> _ultimosMeses(int quantidade) {
    final agora = DateTime.now();
    final formato = DateFormat('MMM', 'pt_BR');
    return List.generate(quantidade, (posicao) {
      final mes = DateTime(agora.year, agora.month - (quantidade - 1 - posicao));
      final nome = formato.format(mes).replaceAll('.', '');
      return MesDesempenho(
        rotulo: nome[0].toUpperCase() + nome.substring(1),
        valor: 0,
      );
    });
  }
}
