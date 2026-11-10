import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';
import 'indicador_etapa.dart';

class PaginaCadastro extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final int etapaAtual;

  final List<Widget> children;

  final double espacoAposVoltar;

  final double espacoAposIndicador;

  const PaginaCadastro({
    super.key,
    required this.formKey,
    required this.etapaAtual,
    required this.children,
    this.espacoAposVoltar = 8,
    this.espacoAposIndicador = 20,
  });

  static const double _larguraMaxima = 480;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _larguraMaxima),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.fundoCartao,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.textoEscuro,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: espacoAposVoltar),
                      IndicadorEtapa(etapaAtual: etapaAtual),
                      SizedBox(height: espacoAposIndicador),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
