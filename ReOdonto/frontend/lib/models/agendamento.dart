import '../utils/formatadores.dart';

class StatusAgendamento {
  static const agendado = 'agendado';
  static const concluido = 'concluido';
  static const cancelado = 'cancelado';
}

class Agendamento {
  final int? id;
  final String? paciente;
  final double? avaliacaoPaciente;

  final DateTime? dataHora;

  final String? tipoConsulta;

  final double? preco;

  final int? duracaoMinutos;

  final bool encaixe;

  final String? status;

  const Agendamento({
    this.id,
    this.paciente,
    this.avaliacaoPaciente,
    this.dataHora,
    this.tipoConsulta,
    this.preco,
    this.duracaoMinutos,
    this.encaixe = false,
    this.status,
  });

  bool get vago => paciente == null;

  bool get concluido => status == StatusAgendamento.concluido;

  bool get emAberto => !vago && status == StatusAgendamento.agendado;

  String get rotuloStatus {
    switch (status) {
      case StatusAgendamento.concluido:
        return 'Concluído';
      case StatusAgendamento.cancelado:
        return 'Cancelado';
      default:
        return encaixe ? 'Encaixe' : 'Agendado';
    }
  }

  String get dia => dataHora == null ? '' : formatarDataCurta(dataHora!);

  String get horario => dataHora == null ? '' : formatarHora(dataHora!);

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    final dataHora = DateTime.tryParse(json['data_hora']?.toString() ?? '');

    return Agendamento(
      id: json['id'] as int?,
      paciente: json['paciente_nome'] as String?,
      avaliacaoPaciente: null,
      dataHora: dataHora,
      tipoConsulta: json['consulta_nome'] as String?,
      preco: (json['consulta_valor'] as num?)?.toDouble(),
      duracaoMinutos: (json['duracao_minutos'] as num?)?.toInt(),
      encaixe: json['encaixe'] == true,
      status: (json['status'] as String?)?.toLowerCase(),
    );
  }
}

String formatarPreco(double valor) => formatarMoeda(valor);
