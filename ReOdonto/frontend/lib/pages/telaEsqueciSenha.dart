import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/recuperarSenha/campo_login.dart';
import '../widgets/recuperarSenha/pagina_autenticacao.dart';
import 'telaNovaSenha.dart';
import '../utils/avisos.dart';
import '../widgets/botao_principal.dart';

class TelaRedefinirSenha extends StatefulWidget {
  const TelaRedefinirSenha({super.key});

  @override
  State<TelaRedefinirSenha> createState() => _TelaRedefinirSenhaState();
}

class _TelaRedefinirSenhaState extends State<TelaRedefinirSenha> {
  final _controladorEmail = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _controladorEmail.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final email = _controladorEmail.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      mostrarAviso(context, 'Digite um email válido', erro: true);
      return;
    }

    setState(() => _carregando = true);

    final resultado = await ApiService.solicitarCodigoRecuperacao(email: email);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado.temErro) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TelaNovaSenha(email: email)));
  }

  @override
  Widget build(BuildContext context) {
    return PaginaAutenticacao(
      children: [
        const TituloAutenticacao(
          titulo: 'Redefinir Senha',
          subtitulo:
              'Informe o e-mail para qual você deseja redefinir sua senha',
        ),

        CampoLogin(
          controller: _controladorEmail,
          hintText: 'E-mail',
          enabled: !_carregando,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        BotaoPrincipal(
          texto: 'Continuar',
          carregando: _carregando,
          cor: const Color(0xFF1E5FD8),
          onPressed: _carregando ? null : _continuar,
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _carregando ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Voltar para tela login',
              style: TextStyle(
                color: Color(0xFF00C1A2),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
