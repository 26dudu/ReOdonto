import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'sessao_usuario.dart';

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

class GoogleService {
  GoogleService._();

  static final _googleSignIn = GoogleSignIn(
    clientId: '257323228205-sc45fgcp8aakbd4rocnovlm0n4li7d00.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  static Future<ResultadoGoogle> entrar() async {
    try {
      final conta = await _googleSignIn.signIn();
      if (conta == null) {
        return const GoogleCancelado();
      }

      final auth = await conta.authentication;
      final idToken     = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null && accessToken == null) {
        return const GoogleErro('Não foi possível obter o token do Google.');
      }

      final resultado = await ApiService.loginGoogle(
        idToken:     idToken,
        accessToken: accessToken,
      );

      if (resultado.temErro) {
        await _googleSignIn.signOut();
        return GoogleErro(resultado.erro!);
      }

      await SessaoUsuario.salvar(resultado.dados!);

      return const GoogleSucesso();
    } catch (e) {
      return GoogleErro('Erro inesperado: $e');
    }
  }

  static Future<void> sair() async {
    await _googleSignIn.signOut();
  }
}
