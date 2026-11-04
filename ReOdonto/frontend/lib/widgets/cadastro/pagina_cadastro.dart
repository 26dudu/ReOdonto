import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';
import 'indicador_etapa.dart';

// NOVO WIDGET: telaCadastro.dart e telaSenhaCadastro.dart tinham ~60 linhas
// idênticas de "casca": Scaffold + SafeArea + rolagem + cartão branco com
// sombra + Form + botão de voltar + indicador de etapa. Agora a casca vive
// aqui e cada tela só entrega os campos (children).

/// Casca padrão das telas do cadastro (cartão branco centralizado com Form).
class PaginaCadastro extends StatelessWidget {
  /// Chave do Form: a tela usa para chamar `validate()` nos campos.
  final GlobalKey<FormState> formKey;

  /// Etapa destacada no indicador (0 = dados pessoais, 1 = senha).
  final int etapaAtual;

  /// Conteúdo da tela (cabeçalho, campos, botão), na ordem de cima para baixo.
  final List<Widget> children;

  /// Espaço entre o botão de voltar e o indicador de etapa.
  final double espacoAposVoltar;

  /// Espaço entre o indicador de etapa e o primeiro item de [children].
  final double espacoAposIndicador;

  const PaginaCadastro({
    super.key,
    required this.formKey,
    required this.etapaAtual,
    required this.children,
    this.espacoAposVoltar = 8,
    this.espacoAposIndicador = 20,
  });

  // Largura máxima do cartão do formulário.
  static const double _larguraMaxima = 480;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo azul claro padrão.
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        // Rolagem vertical (necessária quando o teclado abre).
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              // Limita a largura do cartão em telas grandes.
              constraints: const BoxConstraints(maxWidth: _larguraMaxima),
              // Cartão branco com sombra suave.
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
                // Form agrupa os campos para a validação conjunta.
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Linha com o botão de voltar (pop volta para a tela anterior).
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            // Sem espaçamentos extras do botão.
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
                      // Barrinhas "etapa X de 2".
                      IndicadorEtapa(etapaAtual: etapaAtual),
                      SizedBox(height: espacoAposIndicador),
                      // Conteúdo específico de cada tela.
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
