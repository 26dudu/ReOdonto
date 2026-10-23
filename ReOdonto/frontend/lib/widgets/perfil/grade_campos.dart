import 'package:flutter/material.dart';

/// Distribui [filhos] em [colunas] colunas de larguras iguais.
/// No celular use 1 coluna; no desktop, 2.
class GradeCampos extends StatelessWidget {
  final List<Widget> filhos;
  final int colunas;

  const GradeCampos({super.key, required this.filhos, this.colunas = 1});

  static const double _espacoH = 20;
  static const double _espacoV = 14;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final largura =
            (restricoes.maxWidth - _espacoH * (colunas - 1)) / colunas;
        return Wrap(
          spacing: _espacoH,
          runSpacing: _espacoV,
          children: [
            for (final f in filhos) SizedBox(width: largura, child: f),
          ],
        );
      },
    );
  }
}
