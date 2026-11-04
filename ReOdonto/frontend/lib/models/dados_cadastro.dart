// NOVO MODEL: antes a tela de cadastro (etapa 1) passava 5 textos soltos para a
// tela de senha (etapa 2). Agora eles viajam juntos neste objeto, e se um dia
// for preciso um campo novo (ex.: data de nascimento) basta mexer aqui.

/// Dados pessoais digitados na 1ª etapa do cadastro do dentista.
class DadosCadastro {
  final String nome;
  final String email;
  final String telefone;
  final String cpfCnpj;

  /// CRO é opcional: quando não digitado, fica como texto vazio.
  final String cro;

  const DadosCadastro({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpfCnpj,
    required this.cro,
  });
}
