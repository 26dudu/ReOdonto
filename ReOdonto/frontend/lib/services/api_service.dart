import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'sessao_usuario.dart';

/// URL base da API — detecta a plataforma automaticamente.
/// - Emulador Android: http://10.0.2.2:5000
/// - iOS simulator / web: http://127.0.0.1:5000
/// - Dispositivo físico na mesma rede: troque pelo IP da máquina
String get _baseUrl {
  if (kIsWeb) return 'http://127.0.0.1:5000';
  if (Platform.isAndroid) return 'http://10.0.2.2:5000';
  return 'http://127.0.0.1:5000';
}

Map<String, String> get _headersPublicos => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

/// Headers com JWT — usar em rotas protegidas
Map<String, String> get _headersAuth {
  final token = SessaoUsuario.token;
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

/// Resultado genérico de uma chamada HTTP.
class ApiResultado<T> {
  final T? dados;
  final String? erro;
  final bool sessaoExpirada; // true quando o backend retorna 401

  const ApiResultado.sucesso(this.dados)
      : erro = null,
        sessaoExpirada = false;

  const ApiResultado.falha(this.erro, {this.sessaoExpirada = false})
      : dados = null;

  bool get temErro => erro != null;
}

/// Verifica se a resposta é 401 e retorna o resultado adequado.
ApiResultado<T> _tratarResposta401<T>(http.Response response, T dados) {
  if (response.statusCode == 401) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ApiResultado.falha(
      body['erro'] ?? 'Sessão expirada. Faça login novamente.',
      sessaoExpirada: true,
    );
  }
  return ApiResultado.sucesso(dados);
}

class ApiService {
  // ----------------------------------------------------------------
  // CADASTRO — POST /pacientes/
  // ----------------------------------------------------------------
  static Future<ApiResultado<Map<String, dynamic>>> cadastrar({
    required String nome,
    required String email,
    required String senha,
    String? telefone,
    String? cpf,
    String? cep,
    String? rua,
    String? bairro,
    String? numero,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/pacientes/'),
            headers: _headersPublicos,
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'senha': senha,
              if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
              if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
              if (cep != null && cep.isNotEmpty) 'cep': cep,
              if (rua != null && rua.isNotEmpty) 'rua': rua,
              if (bairro != null && bairro.isNotEmpty) 'bairro': bairro,
              if (numero != null && numero.isNotEmpty) 'numero': numero,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) return ApiResultado.sucesso(body);
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

  // ----------------------------------------------------------------
  // LOGIN — POST /pacientes/login
  // Retorna { token, paciente }
  // ----------------------------------------------------------------
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

  // ----------------------------------------------------------------
  // BUSCA CEP — direto na BrasilAPI (não passa pelo backend)
  // Retorna { cep, logradouro, bairro, cidade, estado }
  // ----------------------------------------------------------------
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

  // ----------------------------------------------------------------
  // CLÍNICAS — GET /clinicas/?page=1&per_page=20
  // ----------------------------------------------------------------
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

  // ----------------------------------------------------------------
  // AGENDAMENTOS — GET /agendamentos/
  // ----------------------------------------------------------------
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

  // ----------------------------------------------------------------
  // CRIAR AGENDAMENTO — POST /agendamentos/
  // ----------------------------------------------------------------
  static Future<ApiResultado<Map<String, dynamic>>> criarAgendamento({
    required int dentistaId,
    required int consultaId,
    required int clinicaId,
    required String dataHora, // ISO 8601: "2025-08-15T14:00:00"
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/agendamentos/'),
            headers: _headersAuth,
            body: jsonEncode({
              'dentista_id': dentistaId,
              'consulta_id': consultaId,
              'clinica_id': clinicaId,
              'data_hora': dataHora,
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

  // ----------------------------------------------------------------
  // CANCELAR AGENDAMENTO — PATCH /agendamentos/<id>/status
  // ----------------------------------------------------------------
  static Future<ApiResultado<Map<String, dynamic>>> cancelarAgendamento(
      int id) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/agendamentos/$id/status'),
            headers: _headersAuth,
            body: jsonEncode({'status': 'cancelado'}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return ApiResultado.sucesso(body);
      return ApiResultado.falha(body['erro'] ?? 'Erro ao cancelar agendamento');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  // ----------------------------------------------------------------
  // BUSCAR PERFIL — GET /pacientes/<id>
  // ----------------------------------------------------------------
  static Future<ApiResultado<Map<String, dynamic>>> buscarPerfil(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/pacientes/$id'),
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

  // ----------------------------------------------------------------
  // ATUALIZAR PERFIL — PUT /pacientes/<id>
  // ----------------------------------------------------------------
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
            Uri.parse('$_baseUrl/pacientes/$id'),
            headers: _headersAuth,
            body: jsonEncode({
              'nome': nome,
              if (email != null && email.isNotEmpty) 'email': email,
              if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
              if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
              if (cep != null && cep.isNotEmpty) 'cep': cep,
              if (rua != null && rua.isNotEmpty) 'rua': rua,
              if (bairro != null && bairro.isNotEmpty) 'bairro': bairro,
              if (numero != null && numero.isNotEmpty) 'numero': numero,
              if (senha != null && senha.isNotEmpty) 'senha': senha,
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

  // ----------------------------------------------------------------
  // LISTAR DENTISTAS — GET /dentistas/?clinica_id=X (opcional)
  // ----------------------------------------------------------------
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

  // ----------------------------------------------------------------
  // LISTAR CONSULTAS — GET /consultas/
  // ----------------------------------------------------------------
  static Future<ApiResultado<List<dynamic>>> listarConsultas() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/consultas/'), headers: _headersAuth)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResultado.sucesso(jsonDecode(response.body) as List<dynamic>);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResultado.falha(body['erro'] ?? 'Erro ao listar consultas');
    } on SocketException {
      return const ApiResultado.falha('Sem conexão com o servidor.');
    } catch (e) {
      return ApiResultado.falha('Erro inesperado: $e');
    }
  }

  // ----------------------------------------------------------------
  // DELETAR PERFIL — DELETE /pacientes/<id>
  // ----------------------------------------------------------------
  static Future<ApiResultado<void>> deletarConta(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/pacientes/$id'),
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
}

