import '../utils/formatadores.dart';

/// Status exatamente como o backend envia.
///
/// Antes o app esperava 'Confirmado' / 'Pendente', que o backend nunca
/// mandou: ele usa 'agendado', 'concluido' e 'cancelado'. Por isso o botão
/// "Confirmar Atendimento" nunca aparecia e toda bolinha ficava laranja.
class StatusAgendamento {
  static const agendado = 'agendado';
  static const concluido = 'concluido';
  static const cancelado = 'cancelado';
}

class Agendamento {
  final int? id;
  final String? paciente;
  final double? avaliacaoPaciente;

  /// Data e hora completas da consulta (null se a API mandou algo inválido).
  final DateTime? dataHora;

  /// Nome do procedimento (ex.: "Limpeza Dental").
  final String? tipoConsulta;

  /// Valor do horário em R$ (campo `consulta_valor` da API).
  final double? preco;

  /// Duração em minutos.
  final int? duracaoMinutos;

  /// true quando o horário estava vago e foi preenchido por um encaixe.
  final bool encaixe;

  /// Um dos valores de [StatusAgendamento], em minúsculas como na API.
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

  /// Agendado com paciente: pode ser confirmado como atendido ou cancelado.
  bool get emAberto => !vago && status == StatusAgendamento.agendado;

  /// Texto da pílula de status.
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

  /// "28/09" — calculado a partir do dataHora.
  String get dia => dataHora == null ? '' : formatarDataCurta(dataHora!);

  /// "14:30" — calculado a partir do dataHora.
  String get horario => dataHora == null ? '' : formatarHora(dataHora!);

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    // tryParse não lança erro se o texto for inválido: devolve null.
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

/// 200.0 -> "R$ 200,00" (usa o intl).
String formatarPreco(double valor) => formatarMoeda(valor);
