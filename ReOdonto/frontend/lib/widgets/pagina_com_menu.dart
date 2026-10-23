import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'menu_navegacao.dart';
import 'logo_dente.dart';

// "Moldura" das páginas
// Cuida de tudo que era repetido em cada tela:


// A tela só entrega o [corpo] (o conteúdo em si).
class PaginaComMenu extends StatelessWidget {
  final PaginaApp pagina;
  // Recebe `celular` (true/false) para a tela variar o que precisar.
  final Widget Function(bool celular) corpo;

  final bool carregando;
  final String? erro;
  final VoidCallback? onTentarNovamente;

  // Se informado, liga o "puxar para atualizar".
  final Future<void> Function()? onAtualizar;

  final Widget? botaoFlutuante;

  //Só desktop: título à esquerda do cabeçalho e botões antes do logo.
  final Widget? tituloDesktop;
  final List<Widget> acoesDesktop;

  // Só desktop: largura máxima do conteúdo (null = ocupa tudo).
  final double? larguraMaxima;

  const PaginaComMenu({
    super.key,
    required this.pagina,
    required this.corpo,
    this.carregando = false,
    this.erro,
    this.onTentarNovamente,
    this.onAtualizar,
    this.botaoFlutuante,
    this.tituloDesktop,
    this.acoesDesktop = const [],
    this.larguraMaxima,
  });

  static const double _quebraCelular = 700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      drawer: MenuSanduiche(paginaAtiva: pagina),
      floatingActionButton: botaoFlutuante,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricoes) => restricoes.maxWidth < _quebraCelular
              ? _celular()
              : _desktop(),
        ),
      ),
    );
  }

  /// O que aparece no lugar do corpo enquanto carrega ou se deu erro.
  Widget _conteudo(bool celular) {
    if (carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (erro != null) {
      return EstadoErro(mensagem: erro!, onTentarNovamente: onTentarNovamente);
    }
    return corpo(celular);
  }

  // Envolve em RefreshIndicator só se a tela pediu.
  // AlwaysScrollable: permite "puxar" mesmo com pouco conteúdo.
  Widget _rolavel({required EdgeInsets padding, required Widget filho}) {
    final rolagem = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: filho,
    );
    return onAtualizar == null
        ? rolagem
        : RefreshIndicator(onRefresh: onAtualizar!, child: rolagem);
  }

  Widget _celular() {
    return _rolavel(
      padding: const EdgeInsets.all(20),
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [BotaoMenuSanduiche(), LogoDente()],
          ),
          const SizedBox(height: 24),
          _conteudo(true),
        ],
      ),
    );
  }

  Widget _desktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarraLateralMenu(paginaAtiva: pagina),
        Expanded(
          child: _rolavel(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            filho: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: larguraMaxima ?? double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        tituloDesktop ?? const SizedBox.shrink(),
                        Row(children: [...acoesDesktop, const LogoDente()]),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _conteudo(false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Mensagem de erro + botão "Tentar novamente".
class EstadoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback? onTentarNovamente;

  const EstadoErro({super.key, required this.mensagem, this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoCinza, fontSize: 14),
            ),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onTentarNovamente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
