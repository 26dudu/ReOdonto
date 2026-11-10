import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'sessao_usuario.dart';

String get _baseUrl {
  if (kIsWeb) return 'http://127.0.0.1:5000';
  if (Platform.isAndroid) return 'http://10.0.2.2:5000';
  return 'http://127.0.0.1:5000';
}

Map<String, String> get _headersPublicos => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

Map<String, String> get _headersAuth {
  final token = SessaoUsuario.token;
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

class ApiResultado<T> {
  final T? dados;
  final String? erro;

  const ApiResultado.sucesso(this.dados) : erro = null;
  const ApiResultado.falha(this.erro) : dados = null;

  bool get temErro => erro != null;
}

class ApiService {
  static Future<ApiResultado<Map<String, dynamic>>> cadastrar({
    required String nome,
    required String email,
    required String senha,
    String? telefone,
    String? cpfCnpj,
    String? cro,
    String? cpf,
    String? cep,
    String? rua,
    String? bairro,
    String? numero,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/dentistas/'),
            headers: _headersPublicos,
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'senha': senha,
              if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
              if (cpfCnpj != null && cpfCnpj.isNotEmpty) 'cpf_cnpj': cpfCnpj,
              if (cro != null && cro.isNotEmpty) 'cro': cro,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 202) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao criar conta');
    } on SocketException {
      return const ApiResultado.falha(
          'Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> loginDentista({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/dentistas/login'),
            headers: _headersPublicos,
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Email ou senha inválidos');
    } on SocketException {
      return const ApiResultado.falha(
          'Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> verificarEmail({
    required String email,
    required String codigo,
  }) =>
      _postPublico(
        '/dentistas/verificar-email',
        {'email': email, 'codigo': codigo},
        erroPadrao: 'Código inválido ou expirado',
      );

  static Future<ApiResultado<Map<String, dynamic>>> reenviarVerificacaoEmail({
    required String email,
  }) =>
      _postPublico(
        '/dentistas/reenviar-verificacao',
        {'email': email},
        erroPadrao: 'Erro ao reenviar o código',
      );

  static Future<ApiResultado<Map<String, dynamic>>> _postPublico(
    String caminho,
    Map<String, dynamic> corpo, {
    required String erroPadrao,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$caminho'),
            headers: _headersPublicos,
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResultado.sucesso(body);
      }
      return ApiResultado.falha(body['erro'] ?? erroPadrao);
    } on SocketException {
      return const ApiResultado.falha(
          'Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/pacientes/login'),
            headers: _headersPublicos,
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Email ou senha inválidos');
    } on SocketException {
      return const ApiResultado.falha(
          'Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');
    if (cepLimpo.length != 8) {
      return const ApiResultado.falha('CEP deve ter 8 dígitos');
    }
    try {
      final response = await http
          .get(
            Uri.parse('https://brasilapi.com.br/api/cep/v2/$cepLimpo'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return const ApiResultado.falha('CEP não encontrado');
      }
      if (response.statusCode != 200) {
        return const ApiResultado.falha('Erro ao consultar o CEP');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResultado.sucesso({
        'cep': data['cep'] ?? cepLimpo,
        'logradouro': data['street'] ?? '',
        'bairro': data['neighborhood'] ?? '',
        'cidade': data['city'] ?? '',
        'estado': data['state'] ?? '',
      });
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com a internet.');
    } catch (e) {
      return ApiResultado.falha('Erro ao buscar CEP: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> listarClinicas({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/clinicas/')
          .replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});
      final response = await http
          .get(uri, headers: _headersAuth)
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao listar clínicas');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<List<dynamic>>> listarAgendamentos() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/agendamentos/'), headers: _headersAuth)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResultado.sucesso(jsonDecode(response.body) as List<dynamic>);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResultado.falha(body['erro'] ?? 'Erro ao listar agendamentos');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> criarAgendamento({
    required int dentistaId,
    required String dataHora,
    String? nomePaciente,
    String? telefonePaciente,
    int? clinicaId,
    String? consultaCustomizada,
    double? valor,
    int? duracaoMinutos,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/agendamentos/'),
            headers: _headersAuth,
            body: jsonEncode({
              'dentista_id': dentistaId,
              'data_hora': dataHora,
              if (nomePaciente != null && nomePaciente.isNotEmpty)
                'nome_paciente': nomePaciente,
              if (telefonePaciente != null && telefonePaciente.isNotEmpty)
                'telefone_paciente': telefonePaciente,
              if (clinicaId != null) 'clinica_id': clinicaId,
              if (consultaCustomizada != null) 'consulta_customizada': consultaCustomizada,
              if (valor != null) 'valor': valor,
              if (duracaoMinutos != null) 'duracao_minutos': duracaoMinutos,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao criar agendamento');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> _atualizarStatus(
    int id,
    String status,
    String mensagemErro,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/agendamentos/$id/status'),
            headers: _headersAuth,
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? mensagemErro);
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> cancelarAgendamento(int id) =>
      _atualizarStatus(id, 'cancelado', 'Erro ao cancelar agendamento');

  static Future<ApiResultado<Map<String, dynamic>>> concluirAgendamento(int id) =>
      _atualizarStatus(id, 'concluido', 'Erro ao confirmar atendimento');

  static Future<ApiResultado<Map<String, dynamic>>> buscarResumoPainel() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/painel/resumo'), headers: _headersAuth)
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao carregar o painel');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> agendarPacienteRapido({
    required int agendamentoId,
    required String nome,
    required String telefone,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/agendamentos/$agendamentoId/paciente-rapido'),
            headers: _headersAuth,
            body: jsonEncode({'nome': nome, 'telefone': telefone}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao agendar paciente');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> solicitarCodigoRecuperacao({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/dentistas/recuperar-senha'),
            headers: _headersPublicos,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao enviar o código');
    } on SocketException {
      return const ApiResultado.falha(
          'Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/dentistas/redefinir-senha'),
            headers: _headersPublicos,
            body: jsonEncode({
              'email': email,
              'codigo': codigo,
              'nova_senha': novaSenha,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Código inválido ou expirado');
    } on SocketException {
      return const ApiResultado.falha(
          'Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<List<dynamic>>> listarDentistas({int? clinicaId}) async {
    try {
      final uri = Uri.parse('$_baseUrl/dentistas/').replace(
        queryParameters: clinicaId != null ? {'clinica_id': '$clinicaId'} : null,
      );
      final response = await http
          .get(uri, headers: _headersAuth)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResultado.sucesso(jsonDecode(response.body) as List<dynamic>);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResultado.falha(body['erro'] ?? 'Erro ao listar dentistas');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> buscarPerfil(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/dentistas/$id'),
            headers: _headersAuth,
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao buscar perfil');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> atualizarPerfil(
    int id, {
    required String nome,
    String? email,
    String? telefone,
    String? cpf,
    String? cep,
    String? rua,
    String? bairro,
    String? numero,
    String? senha,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/dentistas/$id'),
            headers: _headersAuth,
            body: jsonEncode({
              'nome': nome,
              if (email != null && email.isNotEmpty) 'email': email,
              if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao atualizar perfil');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<void>> deletarConta(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/dentistas/$id'),
            headers: _headersAuth,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 204) return const ApiResultado.sucesso(null);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResultado.falha(body['erro'] ?? 'Erro ao deletar conta');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  static Future<ApiResultado<Map<String, dynamic>>> loginGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/google/verify-token'),
            headers: _headersPublicos,
            body: jsonEncode({
              if (idToken != null) 'id_token': idToken,
              if (accessToken != null) 'access_token': accessToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao autenticar com Google');
    } on SocketException {
      return const ApiResultado.falha(
          'Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      return const ApiResultado.falha('Erro de conexão. Tente novamente.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }
}
