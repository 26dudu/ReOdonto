
class Agendamento {
  final int? id; 
  final String? paciente;
  final double? avaliacaoPaciente;
  final String dia;
  final String horario;
  final double? preco;
  final String? status; // 'Confirmado' ou 'Pendente'

  const Agendamento({
    this.id,
    this.paciente,
    this.avaliacaoPaciente,
    required this.dia,
    required this.horario,
    this.preco,
    this.status,
  });

  bool get vago => paciente == null;

  Agendamento copyWith({String? status}) => Agendamento(
        id: id,
        paciente: paciente,
        avaliacaoPaciente: avaliacaoPaciente,
        dia: dia,
        horario: horario,
        preco: preco,
        status: status ?? this.status,
      );

 
  factory Agendamento.fromJson(Map<String, dynamic> json) {

    final dataHora = DateTime.tryParse(json['data_hora']?.toString() ?? '');

    return Agendamento(
      id: json['id'] as int?,
      paciente: json['paciente_nome'] as String?,
      avaliacaoPaciente: null, 
      dia: dataHora == null
          ? ''
          : '${dataHora.day.toString().padLeft(2, '0')}/'
              '${dataHora.month.toString().padLeft(2, '0')}',
      horario: dataHora == null
          ? ''
          : '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}',
      preco: (json['consulta_valor'] as num?)?.toDouble(),
      status: capitalizar(json['status'] as String?),
    );
  }
}


String? capitalizar(String? valor) {
  if (valor == null || valor.isEmpty) return valor;
  return valor[0].toUpperCase() + valor.substring(1).toLowerCase();
}

String formatarPreco(double valor) {
  return 'R\$${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}


String tituloHorariosVagos(List<String> horarios) {
  if (horarios.isEmpty) return 'Horários vagos:';
  if (horarios.length == 1) return 'Horários vagos: ${horarios.first}:';
  final inicio = horarios.sublist(0, horarios.length - 1).join(', ');
  return 'Horários vagos: $inicio e ${horarios.last}:';
}