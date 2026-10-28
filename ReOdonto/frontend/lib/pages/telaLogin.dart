import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../services/google_service.dart';
import '../utils/avisos.dart';
import '../widgets/botao_principal.dart';
import '../widgets/recuperarSenha/cabecalho_marca.dart';
import '../widgets/recuperarSenha/campo_login.dart';
import 'telaCadastro.dart';
import 'telaEsqueciSenha.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  static const _azul = Color(0xFF1E5FD8);
  static const _verde = Color(0xFF00C1A2);

  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;
  bool _carregandoGoogle = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final email = _email.text.trim();
    final senha = _senha.text;

    if (email.isEmpty || !email.contains('@')) {
      return mostrarAviso(context, 'Digite um email válido', erro: true);
    }
    if (senha.isEmpty) {
      return mostrarAviso(context, 'Digite sua senha', erro: true);
    }

    setState(() => _carregando = true);

    // O app é do dentista. Antes, se o login de dentista falhasse, o app
    // tentava como paciente — e o paciente entrava numa agenda em que toda
    // chamada é recusada (as rotas exigem token de dentista).
    final resultado = await ApiService.loginDentista(email: email, senha: senha);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado.temErro) {
      return mostrarAviso(context, resultado.erro!, erro: true);
    }

    await SessaoUsuario.salvar(resultado.dados!);
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      SessaoUsuario.ehDentista ? '/agenda' : '/perfil',
    );
    mostrarAviso(context, 'Bem-vindo, ${SessaoUsuario.nome}!');
  }

  void _abrir(Widget tela) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  Future<void> _loginGoogle() async {
    setState(() => _carregandoGoogle = true);

    final resultado = await GoogleService.entrar();

    if (!mounted) return;
    setState(() => _carregandoGoogle = false);

    switch (resultado) {
      case GoogleSucesso():
        Navigator.of(context).pushReplacementNamed(
          SessaoUsuario.ehDentista ? '/agenda' : '/perfil',
        );
        mostrarAviso(context, 'Bem-vindo, ${SessaoUsuario.nome}!');
      case GoogleCancelado():
        // Usuário fechou o seletor — não exibe erro
        break;
      case GoogleErro(:final mensagem):
        mostrarAviso(context, mensagem, erro: true);
    }
  }

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 32 : 48,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const CabecalhoMarca(),
                  const SizedBox(height: 40),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 16, color: Color(0xFF1C2434)),
                      children: [
                        TextSpan(text: 'Faça login em sua conta '),
                        TextSpan(
                          text: 'ReOdonto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _azul,
                          ),
                        ),
                        TextSpan(text: '!'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _rotulo('Email'),
                  CampoLogin(
                    controller: _email,
                    hintText: 'Digite seu email',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_carregando && !_carregandoGoogle,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: 20),
                  _rotulo('Senha'),
                  CampoLogin(
                    controller: _senha,
                    hintText: 'Digite sua senha',
                    obscureText: _ocultarSenha,
                    enabled: !_carregando && !_carregandoGoogle,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: _carregando || _carregandoGoogle
                          ? null
                          : () => setState(() => _ocultarSenha = !_ocultarSenha),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _carregando || _carregandoGoogle
                          ? null
                          : () => _abrir(const TelaRedefinirSenha()),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'Esqueci minha senha',
                        style: TextStyle(color: _verde, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BotaoPrincipal(
                    texto: 'Entrar',
                    carregando: _carregando,
                    cor: _azul,
                    onPressed: _carregando || _carregandoGoogle ? null : _fazerLogin,
                  ),
                  const SizedBox(height: 20),

                  // ── Divisor ──────────────────────────────────────────
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFCBD5E0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8C9AAB),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFCBD5E0))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Botão Google ──────────────────────────────────────
                  _carregandoGoogle
                      ? const SizedBox(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : SignInButton(
                          Buttons.google,
                          text: 'Entrar com Google',
                          onPressed: _carregando || _carregandoGoogle
                              ? () {}
                              : _loginGoogle,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Ainda não tem uma conta? ',
                          style: TextStyle(fontSize: 14)),
                      GestureDetector(
                        onTap: _carregando || _carregandoGoogle
                            ? null
                            : () => _abrir(const SignupPage()),
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: _azul,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
