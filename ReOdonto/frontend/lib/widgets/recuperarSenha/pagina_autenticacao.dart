import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';
import 'cabecalho_marca.dart';

// NOVO WIDGET: telaLogin, telaEsqueciSenha e telaNovaSenha repetiam a mesma
// casca (Scaffold + SafeArea + rolagem + coluna centralizada de 440 px +
// CabecalhoMarca). Agora a casca vive aqui; cada tela entrega só o conteúdo.

/// Casca das telas de autenticação (login e recuperação de senha).
class PaginaAutenticacao extends StatelessWidget {
  /// Conteúdo que vem logo abaixo do cabeçalho da marca.
  final List<Widget> children;

  const PaginaAutenticacao({super.key, required this.children});

  // Largura máxima do formulário (evita ficar esticado em telas grandes).
  static const double _larguraMaxima = 440;
  // Abaixo de 600 px de largura a tela é considerada "celular".
  static const double _quebraCelular = 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Azul claríssimo (mesmo valor 0xFFF3F8FF usado antes em cada tela).
      backgroundColor: const Color(0xFFF3F8FF),
      body: SafeArea(
        // LayoutBuilder dá o tamanho disponível para adaptar a margem lateral.
        child: LayoutBuilder(
          builder: (context, restricoes) {
            final celular = restricoes.maxWidth < _quebraCelular;
            return SingleChildScrollView(
              // Margem lateral: 32 no celular, 48 em telas largas.
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
                      // Logo e nome do app.
                      const CabecalhoMarca(),
                      const SizedBox(height: 40),
                      // Conteúdo específico de cada tela.
                      ...children,
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

/// Título grande + texto explicativo, centralizados (telas de recuperação).
class TituloAutenticacao extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const TituloAutenticacao({
    super.key,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            // w800 = extra negrito.
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2434),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textoCinza),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
