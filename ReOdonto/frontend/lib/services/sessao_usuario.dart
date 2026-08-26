import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia o estado do paciente logado.
///
/// Persiste id, nome, email e token JWT no SharedPreferences.
/// Ao carregar a sessão, verifica se o token JWT ainda é válido
/// decodificando o payload (sem verificar assinatura — isso é responsabilidade
/// do backend a cada requisição). Se o token estiver expirado, a sessão é
/// descartada e o usuário é redirecionado para o login.
class SessaoUsuario {
  SessaoUsuario._();

  static int? id;
  static String? nome;
  static String? email;
  static String? token; // JWT assinado pelo backend

  // -------------------------------------------------------------------
  // Salvar sessão após login/cadastro bem-sucedido
  // Formato esperado: { "token": "...", "paciente": { id, nome, email, ... } }
  // -------------------------------------------------------------------
  static Future<void> salvar(Map<String, dynamic> resposta) async {
    token = resposta['token'] as String?;
    final paciente = resposta['paciente'] as Map<String, dynamic>?;
    if (paciente != null) {
      id = paciente['id'] as int?;
      nome = paciente['nome'] as String?;
      email = paciente['email'] as String?;
    }

    // Fallback: tenta extrair nome/email diretamente dos claims do JWT
    // (útil se o backend omitir o objeto paciente na resposta)
    if (token != null && (nome == null || email == null)) {
      final claims = _decodificarPayloadJwt(token!);
      id ??= int.tryParse(claims['sub']?.toString() ?? '');
      nome ??= claims['nome'] as String?;
      email ??= claims['email'] as String?;
    }

    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token!);
    if (id != null) await prefs.setInt('paciente_id', id!);
    if (nome != null) await prefs.setString('paciente_nome', nome!);
    if (email != null) await prefs.setString('paciente_email', email!);
  }

  // -------------------------------------------------------------------
  // Carregar sessão salva — chamar em main() para auto-login
  // Retorna false se não há sessão ou se o token estiver expirado
  // -------------------------------------------------------------------
  static Future<bool> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    id = prefs.getInt('paciente_id');
    nome = prefs.getString('paciente_nome');
    email = prefs.getString('paciente_email');

    if (token == null || id == null) return false;

    // Verifica expiração do token decodificando o payload JWT localmente
    if (_tokenEstaExpirado(token!)) {
      await limpar();
      return false;
    }

    return true;
  }

  // -------------------------------------------------------------------
  // Limpar sessão no logout
  // -------------------------------------------------------------------
  static Future<void> limpar() async {
    token = null;
    id = null;
    nome = null;
    email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('paciente_id');
    await prefs.remove('paciente_nome');
    await prefs.remove('paciente_email');
  }

  static bool get estaLogado => id != null && token != null && !_tokenEstaExpirado(token!);

  // -------------------------------------------------------------------
  // Decodifica o payload do JWT (parte central, base64url)
  // NÃO verifica assinatura — apenas lê os claims públicos.
  // A verificação real acontece no backend a cada requisição.
  // -------------------------------------------------------------------
  static Map<String, dynamic> _decodificarPayloadJwt(String jwt) {
    try {
      final partes = jwt.split('.');
      if (partes.length != 3) return {};

      // Base64url → base64 padrão
      String payload = partes[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      // Padding
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = utf8.decode(base64Decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Retorna true se o token já expirou (claim `exp` no passado).
  static bool _tokenEstaExpirado(String jwt) {
    try {
      final claims = _decodificarPayloadJwt(jwt);
      final exp = claims['exp'] as int?;
      if (exp == null) return false; // sem `exp` → não verifica
      final expira = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return DateTime.now().toUtc().isAfter(expira);
    } catch (_) {
      return false;
    }
  }
}
