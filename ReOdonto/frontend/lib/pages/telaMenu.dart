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

// MUDANÇAS NESTE ARQUIVO (de 225 para 151 linhas): os 4 cartões do topo viraram
// IndicadoresPainel, a saudação virou SaudacaoPainel e as 4 linhas do resumo
// de 3 meses viraram CartaoResumoTrimestre.deResumo(...).

// Mostra os números do consultório: prejuízo evitado, ociosidade, horários recuperados, pacientes encaixados, resumo de 3 meses e o gráfico mensal
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

    // GET /painel/resumo — o formato do JSON está em models/resumo_painel.dart.
    // RENOMEADO: 'r' agora é 'respostaApi' (resposta (ApiResultado) da chamada buscarResumoPainel).
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

  /// Primeiro nome do dentista logado ("Ana Souza" -> "Ana").
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
    // RENOMEADO: 'r' agora é 'dadosDoPainel' (cópia local do resumo do painel (_resumo)).
    final dadosDoPainel = _resumo;

    // Cada bloco da tela agora é um widget próprio (veja os imports no topo).
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

    // ───── Celular: tudo empilhado ─────
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

    // ───── Desktop: título centrado, 4 cartões na linha, resumo e gráfico ─────
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
