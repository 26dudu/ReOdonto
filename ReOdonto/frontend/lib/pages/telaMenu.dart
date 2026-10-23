import 'package:flutter/material.dart';
import '../models/resumo_painel.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_navegacao.dart';
import '../widgets/pagina_com_menu.dart';
import '../widgets/painel/cartao_indicador.dart';
import '../widgets/painel/cartao_resumo_trimestre.dart';
import '../widgets/painel/grafico_desempenho.dart';

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

    // TODO(backend): trocar por uma chamada à API Python, por exemplo
    //   final r = await ApiService.buscarResumoPainel(SessaoUsuario.id!);
    //   if (r.temErro) { setState(() { _carregando = false; _erro = r.erro; }); return; }
    //   resumo = ResumoPainel.fromJson(r.dados!);
    // O formato do JSON está documentado em models/resumo_painel.dart.


    final resumo = ResumoPainel.vazio();

    if (!mounted) return;
    setState(() {
      _resumo = resumo;
      _carregando = false;
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
    final r = _resumo;

    final indicadores = [
      CartaoIndicador(
        icone: Icons.attach_money,
        corIcone: AppColors.painelTealTexto,
        titulo: 'Prejuízo evitado',
        valor: formatarReaisInteiro(r.prejuizoEvitado),
      ),
      CartaoIndicador(
        icone: Icons.pie_chart_outline,
        corIcone: AppColors.painelRoxo,
        titulo: 'Ociosidade',
        valor: '${r.ociosidade.round()}%',
      ),
      CartaoIndicador(
        icone: Icons.calendar_today_outlined,
        corIcone: AppColors.azulPrimario,
        titulo: 'Horários recuperados',
        valor: '${r.horariosRecuperados}',
      ),
      CartaoIndicador(
        icone: Icons.group_outlined,
        corIcone: AppColors.confirmadoTexto,
        titulo: 'Pacientes encaixados',
        valor: '${r.pacientesEncaixados}',
      ),
    ];

    final resumo = CartaoResumoTrimestre(
      linhas: [
        LinhaResumoTrimestre(
          icone: Icons.event_available_outlined,
          rotulo: 'Consultas realizadas',
          valor: '${r.consultasRealizadas}',
        ),
        LinhaResumoTrimestre(
          icone: Icons.cancel_outlined,
          rotulo: 'Cancelamentos',
          valor: '${r.cancelamentos}',
        ),
        LinhaResumoTrimestre(
          icone: Icons.event_repeat_outlined,
          rotulo: 'Horários recuperados',
          valor: '${r.horariosRecuperados3Meses}',
        ),
        LinhaResumoTrimestre(
          icone: Icons.bar_chart,
          rotulo: 'Taxa de ocupação',
          valor: '${r.taxaOcupacao.round()}%',
        ),
      ],
    );

    final grafico = GraficoDesempenho(dados: r.desempenho, celular: celular);

    final saudacao = Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textoEscuro,
        ),
        children: [
          // "Dr(a)." porque o cadastro ainda não guarda o gênero do dentista.
          const TextSpan(text: 'Olá, Dr(a). '),
          TextSpan(
            text: _primeiroNome,
            style: const TextStyle(color: AppColors.azulPrimario),
          ),
        ],
      ),
    );

    // ───── Celular: tudo empilhado ─────
    if (celular) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          saudacao,
          const SizedBox(height: 20),
          for (final cartao in indicadores) ...[cartao, const SizedBox(height: 14)],
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            //Volta 1 (i = 0): o if (i > 0) é falso, então não coloca espaço. Coloca indicadores[0], o cartão de Prejuízo evitado.
            //Volta 2 (i = 1): o if é verdadeiro, então coloca o espaço de 14 px. Depois coloca indicadores[1], o cartão de Ociosidade.
            //Volta 3 (i = 2): espaço de 14 px, depois indicadores[2], o de Horários recuperados.
            //Volta 4 (i = 3): espaço de 14 px, depois indicadores[3], o de Pacientes encaixados.
            //Fim: o i vira 4, e 4 < indicadores.length (que é 4) é falso, então o for para.
            children: [
              for (int i = 0; i < indicadores.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: indicadores[i]),
              ],
            ],
          ),
        ),
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
