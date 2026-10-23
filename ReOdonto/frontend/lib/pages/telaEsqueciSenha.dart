// Material Design (Scaffold, Text, Column...).
import 'package:flutter/material.dart';
// Paleta de cores do app (AppColors.textoCinza etc.).
import '../theme/app_colors.dart';
// Serviço da API (aqui usado para pedir o código de recuperação).
import '../services/api_service.dart';
// Cabeçalho com logo e nome da marca.
import '../widgets/recuperarSenha/cabecalho_marca.dart';
// Campo de texto estilizado (mesmo usado no login).
import '../widgets/recuperarSenha/campo_login.dart';
// Próxima tela do fluxo: digitar código e nova senha.
import 'telaNovaSenha.dart';
// Função mostrarAviso (SnackBar).
import '../utils/avisos.dart';
// Botão principal reutilizável.
import '../widgets/botao_principal.dart';

// TELA 1 DO FLUXO "ESQUECI A SENHA": o usuário informa o e-mail.
class TelaRedefinirSenha extends StatefulWidget {
  const TelaRedefinirSenha({super.key});

  @override
  State<TelaRedefinirSenha> createState() => _TelaRedefinirSenhaState();
}

class _TelaRedefinirSenhaState extends State<TelaRedefinirSenha> {
  // Controller que guarda o texto digitado no campo de e-mail.
  final _controladorEmail = TextEditingController();
  // true enquanto aguarda a resposta da API.
  bool _carregando = false;

  // Largura máxima do formulário (evita ficar esticado em telas grandes).
  static const double _larguraMaxima = 440;
  // Abaixo de 600 px de largura a tela é considerada "celular".
  static const double _quebraCelular = 600;

  @override
  // Libera o controller quando a tela é destruída.
  void dispose() {
    _controladorEmail.dispose();
    super.dispose();
  }


  // Pede à API que envie um código de recuperação para o e-mail informado.
  Future<void> _continuar() async {
    // Lê o e-mail e remove espaços extras.
    final email = _controladorEmail.text.trim();

    // Validação simples: não vazio e com "@".
    if (email.isEmpty || !email.contains('@')) {
      mostrarAviso(context, 'Digite um email válido', erro: true);
      return;
    }

    // Ativa o estado de carregamento (redesenha a tela).
    setState(() => _carregando = true);

    // Chama a API e espera a resposta.
    final resultado = await ApiService.solicitarCodigoRecuperacao(email: email);

    // Se a tela já foi fechada, não continua.
    if (!mounted) return;
    // Desativa o carregamento.
    setState(() => _carregando = false);

    // Se a API retornou erro, avisa o usuário e para.
    if (resultado.temErro) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }

    // Sucesso: vai para a tela de nova senha, passando o e-mail para ela.
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TelaNovaSenha(email: email)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cor de fundo azul claríssimo (ARGB: alpha, vermelho, verde, azul).
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      // SafeArea: respeita áreas do sistema (notch, barra de status).
      body: SafeArea(
        // LayoutBuilder dá acesso ao tamanho disponível (restricoes) para adaptar o layout.
        child: LayoutBuilder(
          builder: (context, restricoes) {
            // true se a largura disponível for menor que 600 px.
            final celular = restricoes.maxWidth < _quebraCelular;

            // Permite rolagem vertical.
            return SingleChildScrollView(
              // Margem lateral: 32 no celular, 48 em telas largas.
              padding: EdgeInsets.symmetric(
                horizontal: celular ? 32.0 : 48.0,
                vertical: 24.0,
              ),
              // Centraliza o conteúdo.
              child: Center(
                // Limita a largura máxima do conteúdo.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _larguraMaxima),
                  // Coluna vertical com os elementos da tela.
                  child: Column(
                    // Filhos ocupam toda a largura.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                  
                      // Logo e nome do app.
                      const CabecalhoMarca(),

                      const SizedBox(height: 40),
                      // Título da tela.
                      const Text(
                        'Redefinir Senha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          // w800 = extra negrito.
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C2434),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Texto explicativo abaixo do título.
                      const Text(
                        'Informe o e-mail para qual você deseja redefinir sua senha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textoCinza,
                        ),
                      ),
                      const SizedBox(height: 28),

             
                      // Campo onde o usuário digita o e-mail.
                      CampoLogin(
                        // Liga ao controller para ler o texto.
                        controller: _controladorEmail,
                        // Dica quando vazio.
                        hintText: 'E-mail',
                        // Desabilitado durante o carregamento.
                        enabled: !_carregando,
                        // Teclado otimizado para e-mail.
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      // Botão que dispara _continuar.
                      BotaoPrincipal(
                        texto: 'Continuar',
                        // Mostra spinner quando true.
                        carregando: _carregando,
                        cor: const Color(0xFF1E5FD8),
                        // null desabilita o botão.
                        onPressed: _carregando ? null : _continuar,
                      ),
                      const SizedBox(height: 20),
                      // Center para alinhar o link de voltar ao meio.
                      Center(
                        // Texto clicável.
                        child: GestureDetector(
                          // pop() fecha esta tela e volta para a anterior (login).
                          onTap: _carregando
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text(
                            'Voltar para tela login',
                            style: TextStyle(
                              color: Color(0xFF00C1A2),
                              fontSize: 13,
                              // w600 = seminegrito.
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
