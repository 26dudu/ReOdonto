import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';
import 'cabecalho_marca.dart';

class PaginaAutenticacao extends StatelessWidget {
  final List<Widget> children;

  const PaginaAutenticacao({super.key, required this.children});

  static const double _larguraMaxima = 440;
  static const double _quebraCelular = 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
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
                      const CabecalhoMarca(),
                      const SizedBox(height: 40),
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
