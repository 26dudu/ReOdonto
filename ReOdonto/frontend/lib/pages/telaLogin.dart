import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import 'telaCadastro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;

  static const double _larguraMaxima = 440;
  static const double _quebraCelular = 600;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;

    if (email.isEmpty || !email.contains('@')) {
      _mostrarErro('Digite um email válido');
      return;
    }
    if (senha.isEmpty) {
      _mostrarErro('Digite sua senha');
      return;
    }

    setState(() => _carregando = true);

    final resultado = await ApiService.login(email: email, senha: senha);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado.temErro) {
      _mostrarErro(resultado.erro!);
      return;
    }

    await SessaoUsuario.salvar(resultado.dados!);

    if (!mounted) return;

    // TODO: navegar para a tela home quando ela existir
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(builder: (_) => const TelaHome()),
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bem-vindo, ${SessaoUsuario.nome}!')),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricoes) {
            final celular = restricoes.maxWidth < _quebraCelular;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: celular ? 32.0 : 48.0,
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _larguraMaxima),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD0E2FF),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/tooth-svgrepo-com.svg',
                                width: 32,
                                height: 32,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.azulPrimario,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SUA',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00C1A2),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'AGENDA',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1C2434),
                                  height: 0.9,
                                ),
                              ),
                              Text(
                                'CHEIA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C2434),
                                ),
                              ),
                              Text(
                                'CLÍNICAS ODONTOLÓGICAS - AGENDAMENTO ONLINE',
                                style: TextStyle(
                                  fontSize: 6,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Faça login em sua conta ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1C2434),
                            ),
                          ),
                          Text(
                            'ReOdonto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E5FD8),
                            ),
                          ),
                          Text(
                            '!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1C2434),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_carregando,
                        decoration: InputDecoration(
                          hintText: 'Digite seu email',
                          hintStyle: const TextStyle(color: Colors.black26),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color.fromARGB(255, 88, 92, 100),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Senha',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 88, 92, 100),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: senhaController,
                        obscureText: _ocultarSenha,
                        enabled: !_carregando,
                        decoration: InputDecoration(
                          hintText: 'Digite sua senha',
                          hintStyle: const TextStyle(color: Colors.black26),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color.fromARGB(255, 88, 92, 100),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.black45,
                            ),
                            onPressed: _carregando
                                ? null
                                : () => setState(
                                    () => _ocultarSenha = !_ocultarSenha),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _carregando ? null : () {},
                          style:
                              TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              color: Color(0xFF00C1A2),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _carregando ? null : _fazerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5FD8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _carregando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Ainda não tem uma conta? ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: _carregando
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SignupPage(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Cadastre-se',
                              style: TextStyle(
                                color: Color(0xFF1E5FD8),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Color(0xFFE2E8F0), thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('ou',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Color(0xFFE2E8F0), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SignInButton(
                        Buttons.google,
                        text: 'Entrar com Google',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
