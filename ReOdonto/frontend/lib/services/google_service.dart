import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'sessao_usuario.dart';

/// Resultado do fluxo de login com Google.
sealed class ResultadoGoogle {
  const ResultadoGoogle();
}

class GoogleSucesso extends ResultadoGoogle {
  const GoogleSucesso();
}

class GoogleCancelado extends ResultadoGoogle {
  const GoogleCancelado();
}

class GoogleErro extends ResultadoGoogle {
  final String mensagem;
  const GoogleErro(this.mensagem);
}

/// Serviço responsável pelo fluxo completo de autenticação Google.
///
/// Fluxo:
///   1. Abre o seletor de conta Google (GoogleSignIn)
///   2. Obtém o idToken (web) ou accessToken (mobile)
///   3. Envia para POST /auth/google/verify-token no backend
///   4. Backend cria/encontra o paciente e retorna um JWT
///   5. Salva a sessão via SessaoUsuario
class GoogleService {
  GoogleService._();

  static final _googleSignIn = GoogleSignIn(
    clientId: '257323228205-sc45fgcp8aakbd4rocnovlm0n4li7d00.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Executa o login com Google e salva a sessão.
  /// Retorna [GoogleSucesso], [GoogleCancelado] ou [GoogleErro].
  static Future<ResultadoGoogle> entrar() async {
    try {
      // ── 1. Abre o seletor de contas ───────────────────────────────
      final conta = await _googleSignIn.signIn();
      if (conta == null) {
        // Usuário fechou o seletor sem escolher conta
        return const GoogleCancelado();
      }

      // ── 2. Obtém os tokens de autenticação ─────────────────────────
      final auth = await conta.authentication;
      final idToken     = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null && accessToken == null) {
        return const GoogleErro('Não foi possível obter o token do Google.');
      }

      // ── 3. Envia ao backend ────────────────────────────────────────
      final resultado = await ApiService.loginGoogle(
        idToken:     idToken,
        accessToken: accessToken,
      );

      if (resultado.temErro) {
        // Garante que a conta Google local seja desconectada em caso de falha
        await _googleSignIn.signOut();
        return GoogleErro(resultado.erro!);
      }

      // ── 4. Salva a sessão ──────────────────────────────────────────
      await SessaoUsuario.salvar(resultado.dados!);

      return const GoogleSucesso();
    } catch (e) {
      return GoogleErro('Erro inesperado: $e');
    }
  }

  /// Desconecta a conta Google localmente (não faz logout no backend).
  static Future<void> sair() async {
    await _googleSignIn.signOut();
  }
}
