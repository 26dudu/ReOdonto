import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia o estado do usuário logado (paciente ou dentista).
class SessaoUsuario {
  SessaoUsuario._();

  static int? id;
  static String? nome;
  static String? email;
  static String? token;
  static String? tipo; // 'paciente' | 'dentista'

  static bool get ehDentista => tipo == 'dentista';

  // -------------------------------------------------------------------
  // Salvar sessão após login — suporta paciente e dentista
  // Formato: { "token": "...", "paciente": {...} }  OU
  //          { "token": "...", "dentista":  {...} }
  // -------------------------------------------------------------------
  static Future<void> salvar(Map<String, dynamic> resposta) async {
    token = resposta['token'] as String?;

    // Dentista
    final dentista = resposta['dentista'] as Map<String, dynamic>?;
    if (dentista != null) {
      id    = dentista['id'] as int?;
      nome  = dentista['nome'] as String?;
      email = dentista['email'] as String?;
      tipo  = 'dentista';
    }

    // Paciente
    final paciente = resposta['paciente'] as Map<String, dynamic>?;
    if (paciente != null) {
      id    = paciente['id'] as int?;
      nome  = paciente['nome'] as String?;
      email = paciente['email'] as String?;
      tipo  = 'paciente';
    }

    // Fallback via claims JWT
    if (token != null && (nome == null || email == null)) {
      final claims = _decodificarPayloadJwt(token!);
      id   ??= int.tryParse(claims['sub']?.toString() ?? '');
      nome  ??= claims['nome'] as String?;
      email ??= claims['email'] as String?;
      tipo  ??= claims['tipo'] as String?;
    }

    await _persistir();
  }

  // -------------------------------------------------------------------
  // Salvar com parâmetros individuais (Google Auth)
  // -------------------------------------------------------------------
  static Future<void> salvarComParametros({
    required int id,
    required String nome,
    required String email,
    required String token,
    String tipo = 'paciente',
  }) async {
    SessaoUsuario.id    = id;
    SessaoUsuario.nome  = nome;
    SessaoUsuario.email = email;
    SessaoUsuario.token = token;
    SessaoUsuario.tipo  = tipo;
    await _persistir();
  }

  // -------------------------------------------------------------------
  // Carregar sessão salva — retorna false se expirada/inexistente
  // -------------------------------------------------------------------
  static Future<bool> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    id    = prefs.getInt('usuario_id');
    nome  = prefs.getString('usuario_nome');
    email = prefs.getString('usuario_email');
    tipo  = prefs.getString('usuario_tipo') ?? 'paciente';

    if (token == null || id == null) return false;
    if (_tokenEstaExpirado(token!)) { await limpar(); return false; }
    return true;
  }

  // -------------------------------------------------------------------
  // Limpar sessão no logout
  // -------------------------------------------------------------------
  static Future<void> limpar() async {
    token = null; id = null; nome = null; email = null; tipo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_nome');
    await prefs.remove('usuario_email');
    await prefs.remove('usuario_tipo');
    // compatibilidade com chaves antigas
    await prefs.remove('paciente_id');
    await prefs.remove('paciente_nome');
    await prefs.remove('paciente_email');
  }

  static bool get estaLogado =>
      id != null && token != null && !_tokenEstaExpirado(token!);

  // -------------------------------------------------------------------
  // Internos
  // -------------------------------------------------------------------
  static Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token!);
    if (id    != null) await prefs.setInt('usuario_id', id!);
    if (nome  != null) await prefs.setString('usuario_nome', nome!);
    if (email != null) await prefs.setString('usuario_email', email!);
    if (tipo  != null) await prefs.setString('usuario_tipo', tipo!);
  }

  static Map<String, dynamic> _decodificarPayloadJwt(String jwt) {
    try {
      final partes = jwt.split('.');
      if (partes.length != 3) return {};
      String payload = partes[1]
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      while (payload.length % 4 != 0) payload += '=';
      return jsonDecode(utf8.decode(base64Decode(payload))) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static bool _tokenEstaExpirado(String jwt) {
    try {
      final exp = _decodificarPayloadJwt(jwt)['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().toUtc()
          .isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true));
    } catch (_) {
      return false;
    }
  }
}
