import 'package:flutter/material.dart';
import '../models/resumo_painel.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../utils/avisos.dart';
import '../widgets/menu_navegacao.dart';
import '../widgets/pagina_com_menu.dart';
import '../widgets/painel/indicadores_painel.dart';
import '../widgets/painel/cartao_resumo_trimestre.dart';
import '../widgets/painel/grafico_desempenho.dart';
import '../widgets/painel/saudacao_painel.dart';

class TelaMenu extends StatefulWidget {
  const TelaMenu({super.key});

  @override
  State<TelaMenu> createState() => _EstadoTelaMenu();
}

class _EstadoTelaMenu extends State<TelaMenu> {
  ResumoPainel _resumo = ResumoPainel.vazio();
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    final respostaApi = await ApiService.buscarResumoPainel();
    if (!mounted) return;

    if (respostaApi.temErro) {
      if (silencioso) {
        mostrarAviso(context, respostaApi.erro!);
      } else {
        setState(() {
          _carregando = false;
          _erro = respostaApi.erro;
        });
      }
      return;
    }

    setState(() {
      _resumo = ResumoPainel.fromJson(respostaApi.dados!);
      _carregando = false;
      _erro = null;
    });
  }

  String get _primeiroNome {
    final nome = (SessaoUsuario.nome ?? '').trim();
    return nome.isEmpty ? '' : nome.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return PaginaComMenu(
      pagina: PaginaApp.menu,
      carregando: _carregando,
      erro: _erro,
      onTentarNovamente: _carregar,
      onAtualizar: () => _carregar(silencioso: true),
      larguraMaxima: 1000,
      acoesDesktop: [
        IconButton(
          tooltip: 'Atualizar painel',
          onPressed: () => _carregar(silencioso: true),
          icon: const Icon(Icons.refresh, color: AppColors.textoEscuro),
        ),
      ],
      corpo: _conteudo,
    );
  }

  Widget _conteudo(bool celular) {
    final dadosDoPainel = _resumo;

    final indicadores = IndicadoresPainel(
      resumo: dadosDoPainel,
      celular: celular,
    );
    final resumo = CartaoResumoTrimestre.deResumo(dadosDoPainel);
    final grafico = GraficoDesempenho(
      dados: dadosDoPainel.desempenho,
      celular: celular,
    );
    final saudacao = SaudacaoPainel(primeiroNome: _primeiroNome);

    if (celular) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          saudacao,
          const SizedBox(height: 20),
          indicadores,
          const SizedBox(height: 10),
          resumo,
          const SizedBox(height: 28),
          grafico,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Painel Administrativo',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: AppColors.textoEscuro,
            ),
          ),
        ),
        const SizedBox(height: 8),
        saudacao,
        const SizedBox(height: 16),
        indicadores,
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: resumo,
          ),
        ),
        const SizedBox(height: 28),
        grafico,
      ],
    );
  }
}
