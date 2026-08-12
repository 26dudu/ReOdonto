import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia o estado do paciente logado.
/// Persiste id, nome, email e token JWT no SharedPreferences.
class SessaoUsuario {
  SessaoUsuario._();

  static int? id;
  static String? nome;
  static String? email;
  static String? token; // JWT

  /// Salva os dados após login bem-sucedido.
  /// Espera o formato: { "token": "...", "paciente": { id, nome, email, ... } }
  static Future<void> salvar(Map<String, dynamic> resposta) async {
    token = resposta['token'] as String?;
    final paciente = resposta['paciente'] as Map<String, dynamic>?;
    if (paciente != null) {
      id = paciente['id'] as int?;
      nome = paciente['nome'] as String?;
      email = paciente['email'] as String?;
    }

    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token!);
    if (id != null) await prefs.setInt('paciente_id', id!);
    if (nome != null) await prefs.setString('paciente_nome', nome!);
    if (email != null) await prefs.setString('paciente_email', email!);
  }

  /// Carrega a sessão salva — chamar no main() para relogar automaticamente.
  static Future<bool> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    id = prefs.getInt('paciente_id');
    nome = prefs.getString('paciente_nome');
    email = prefs.getString('paciente_email');
    return id != null && token != null;
  }

  /// Limpa tudo no logout.
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

  static bool get estaLogado => id != null && token != null;
}
