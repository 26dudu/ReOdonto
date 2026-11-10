class TipoConsulta {
  final int id;
  final String nome;
  final String? descricao;
  final double valor;
  final int? duracaoMinutos;

  const TipoConsulta({
    required this.id,
    required this.nome,
    this.descricao,
    required this.valor,
    this.duracaoMinutos,
  });

  factory TipoConsulta.fromJson(Map<String, dynamic> json) {
    return TipoConsulta(
      id: json['id'] as int,
      nome: (json['nome'] as String?) ?? '',
      descricao: json['descricao'] as String?,
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      duracaoMinutos: json['duracao_minutos'] as int?,
    );
  }
}
