import '../utils/formatadores.dart';

class Agendamento {
  final int? id;
  final String? paciente;
  final double? avaliacaoPaciente;

  /// Data e hora completas da consulta (null se a API mandou algo inválido).
  final DateTime? dataHora;

  /// Nome do procedimento (ex.: "Limpeza Dental").
  final String? tipoConsulta;

  final double? preco;
  final String? status; // 'Confirmado' ou 'Pendente'

  const Agendamento({
    this.id,
    this.paciente,
    this.avaliacaoPaciente,
    this.dataHora,
    this.tipoConsulta,
    this.preco,
    this.status,
  });

  bool get vago => paciente == null;

  /// "28/09" — calculado a partir do dataHora (antes era um campo guardado).
  String get dia => dataHora == null ? '' : formatarDataCurta(dataHora!);

  /// "14:30" — calculado a partir do dataHora (antes era um campo guardado).
  String get horario => dataHora == null ? '' : formatarHora(dataHora!);

  Agendamento copyWith({String? status}) => Agendamento(
        id: id,
        paciente: paciente,
        avaliacaoPaciente: avaliacaoPaciente,
        dataHora: dataHora,
        tipoConsulta: tipoConsulta,
        preco: preco,
        status: status ?? this.status,
      );

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
      status: capitalizar(json['status'] as String?),
    );
  }
}

String? capitalizar(String? valor) {
  if (valor == null || valor.isEmpty) return valor;
  return valor[0].toUpperCase() + valor.substring(1).toLowerCase();
}

/// 200.0 -> "R$ 200,00" (usa o intl).
String formatarPreco(double valor) => formatarMoeda(valor);
