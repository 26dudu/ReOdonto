import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';

class BotaoGoogleLogin extends StatefulWidget {
  final VoidCallback onLoginSucesso;
  final VoidCallback? onLoginErro;

  const BotaoGoogleLogin({
    super.key,
    required this.onLoginSucesso,
    this.onLoginErro,
  });

  @override
  State<BotaoGoogleLogin> createState() => _BotaoGoogleLoginState();
}

class _BotaoGoogleLoginState extends State<BotaoGoogleLogin> {
  // CLIENT_ID do Google - obtenha do seu projeto Google Console
  static const String _googleClientId = '257323228205-sc45fgcp8aakbd4rocnovlm0n4li7d00.apps.googleusercontent.com';

  late GoogleSignIn _googleSignIn;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      clientId: _googleClientId,
      scopes: [
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email',
      ],
    );
  }

  Future<void> _fazerLoginGoogle() async {
    if (_carregando) return;

    setState(() => _carregando = true);

    try {
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // Web: usar signInSilently para evitar deprecation warning
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          // Se signInSilently falhar, tente signIn normal (vai mostrar dialog)
          googleUser = await _googleSignIn.signIn();
        }
      } else {
        // Mobile: usar signIn normalmente
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        print('=== GOOGLE LOGIN CANCELADO ===');
        if (!mounted) return;
        setState(() => _carregando = false);
        return;
      }

      print('=== GOOGLE USER OBTIDO ===');
      print('Email: ${googleUser.email}');
      print('Display Name: ${googleUser.displayName}');

      // 2. Obtém a autenticação
      final googleAuth = await googleUser.authentication;
      
      print('=== AUTHENTICATION OBTIDA ===');
      
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      // Debug: verificar se tokens existem
      print('=== DEBUG GOOGLE AUTH ===');
      print('idToken: ${idToken != null ? "OK" : "NULL"}');
      print('accessToken: ${accessToken != null ? "OK" : "NULL"}');
      print('Email: ${googleUser.email}');

      // Verifica se pelo menos UM token foi obtido (web tem idToken, mobile pode ter accessToken)
      if (idToken == null && accessToken == null) {
        if (!mounted) return;
        _mostrarErro('Não foi possível obter o código de autenticação');
        setState(() => _carregando = false);
        return;
      }

      // 3. Envia os tokens para o backend
      if (!mounted) return;
      await _enviarTokenParaBackend(idToken: idToken, accessToken: accessToken);
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro ao fazer login: $e');
      setState(() => _carregando = false);
    }
  }

  Future<void> _enviarTokenParaBackend({String? idToken, String? accessToken}) async {
    try {
      final url = Uri.parse('http://localhost:5000/auth/google/verify-token');

      print('=== ENVIANDO PARA BACKEND ===');
      print('URL: $url');
      print('idToken: ${idToken != null ? "enviando" : "null"}');
      print('accessToken: ${accessToken != null ? "enviando" : "null"}');

      final body = <String, dynamic>{};
      if (idToken != null) body['id_token'] = idToken;
      if (accessToken != null) body['access_token'] = accessToken;

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print('=== RESPOSTA DO BACKEND ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (!mounted) return;

      // Verifica se a resposta está vazia
      if (response.body.isEmpty) {
        _mostrarErro('Backend retornou resposta vazia. Verifique se está rodando em localhost:5000');
        setState(() => _carregando = false);
        return;
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final jwtToken = body['token'] as String?;
        final paciente = body['paciente'] as Map<String, dynamic>?;

        if (jwtToken == null || paciente == null) {
          _mostrarErro('Resposta inválida do servidor');
          setState(() => _carregando = false);
          return;
        }

        // 4. Salva na sessão
        await SessaoUsuario.salvarComParametros(
          id: paciente['id'] as int? ?? 0,
          nome: paciente['nome'] as String? ?? '',
          email: paciente['email'] as String? ?? '',
          token: jwtToken,
        );

        // 5. Callback de sucesso
        if (mounted) {
          setState(() => _carregando = false);
          widget.onLoginSucesso();
        }
      } else {
        // Tenta decodificar erro do backend
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final erro = body['erro'] as String? ?? 'Erro desconhecido';
          _mostrarErro(erro);
        } catch (_) {
          _mostrarErro('Erro ${response.statusCode}: ${response.body}');
        }
        setState(() => _carregando = false);
      }
    } on http.ClientException catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro de conexão: Backend não está respondendo em localhost:5000');
      setState(() => _carregando = false);
    } on FormatException catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro ao processar resposta: ${e.message}');
      setState(() => _carregando = false);
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro ao enviar token: $e');
      setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
    widget.onLoginErro?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _carregando ? null : _fazerLoginGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textoEscuro,
          side: const BorderSide(color: AppColors.bordaCampo, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _carregando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.azulPrimario),
                ),
              )
            : const Icon(Icons.login, size: 20, color: AppColors.textoEscuro),
        label: Text(
          _carregando ? 'Entrando...' : 'Entrar com Google',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textoEscuro,
          ),
        ),
      ),
    );
  }
}
