import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/agendamento.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../widgets/agenda/cartao_consulta.dart';
import '../widgets/agenda/dialogo_agendar_paciente.dart';
import '../widgets/agenda/modal_novo_agendamento.dart';
import '../widgets/secoes_texto.dart';
import '../widgets/menu_navegacao.dart';


class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _EstadoTelaAgenda();
}

class _EstadoTelaAgenda extends State<TelaAgenda> {
  static const double _quebraCelular = 700;

  List<Agendamento> _agendamentos = [];
  bool _carregando = true;
  String? _erro;

  List<Agendamento> get _consultasMarcadas =>
      _agendamentos.where((a) => !a.vago).toList();

  List<Agendamento> get _horariosVagos =>
      _agendamentos.where((a) => a.vago).toList();

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await ApiService.listarAgendamentos();

    if (!mounted) return;

    if (resultado.temErro) {
      setState(() {
        _carregando = false;
        _erro = resultado.erro;
      });
      return;
    }

    setState(() {
      _carregando = false;
      _agendamentos = resultado.dados!
          .map((item) => Agendamento.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  void _confirmarAtendimento(Agendamento agendamento) {
    final indice = _agendamentos.indexWhere((a) => a.id == agendamento.id);
    if (indice == -1) return;
    setState(() {
      _agendamentos[indice] = _agendamentos[indice].copyWith(status: 'Confirmado');
    });
  }

  Future<void> _cancelarConsulta(Agendamento agendamento) async {
    if (agendamento.id == null) return;

    final resultado = await ApiService.cancelarAgendamento(agendamento.id!);

    if (!mounted) return;

    if (resultado.temErro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado.erro!)),
      );
      return;
    }

    setState(() {
      _agendamentos.removeWhere((a) => a.id == agendamento.id);
    });
  }

  Future<void> _abrirDialogoAgendarPaciente(Agendamento vago) async {
    if (vago.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar esse horário.'),
        ),
      );
      return;
    }

    final dados = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => DialogoAgendarPaciente(agendamento: vago),
    );

    if (dados == null || !mounted) return;

    final resultado = await ApiService.agendarPacienteRapido(
      agendamentoId: vago.id!,
      nome: dados['nome']!,
      telefone: dados['telefone']!,
    );

    if (!mounted) return;

    if (resultado.temErro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado.erro!)),
      );
      return;
    }

    setState(() {
      final indice = _agendamentos.indexWhere((a) => a.id == vago.id);
      if (indice != -1) {
        _agendamentos[indice] = Agendamento.fromJson(resultado.dados!);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paciente agendado com sucesso!')),
    );
  }

  void _novoAgendamento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModalNovoAgendamento(
        onAgendamentoCriado: _carregarAgendamentos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      drawer: const MenuSanduiche(paginaAtiva: PaginaApp.agenda),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoAgendamento,
        backgroundColor: AppColors.azulPrimario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? _construirErro()
                : LayoutBuilder(
                    builder: (context, restricoes) {
                      final ehCelular = restricoes.maxWidth < _quebraCelular;
                      return ehCelular
                          ? _construirLayoutCelular()
                          : _construirLayoutDesktop();
                    },
                  ),
      ),
    );
  }

  Widget _construirErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoCinza),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarAgendamentos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirLayoutCelular() {
    final marcadas = _consultasMarcadas;
    final vagos = _horariosVagos;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BotaoMenuSanduiche(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD0E2FF),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/tooth-svgrepo-com.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      AppColors.azulPrimario,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Sua agenda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textoEscuro,
            ),
          ),
          const SizedBox(height: 6),
          _saudacao(),
          const SizedBox(height: 20),
          if (marcadas.isNotEmpty) ...[
            const TituloSecao('Consultas do dia:'),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final agendamento in marcadas) ...[
                  CartaoConsulta(
                    consulta: agendamento,
                    onConfirmar: () => _confirmarAtendimento(agendamento),
                    onCancelar: () => _cancelarConsulta(agendamento),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          TituloSecao(
              tituloHorariosVagos(vagos.map((e) => e.horario).toList())),
          const SizedBox(height: 12),
          if (vagos.isEmpty)
            const TextoVazio('Nenhum horário vago hoje.')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final agendamento in vagos) ...[
                  CartaoConsulta(
                    consulta: agendamento,
                    onAgendar: () =>
                        _abrirDialogoAgendarPaciente(agendamento),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _construirLayoutDesktop() {
    final marcadas = _consultasMarcadas;
    final vagos = _horariosVagos;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BarraLateralMenu(paginaAtiva: PaginaApp.agenda),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Sua agenda',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textoEscuro,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _saudacao(),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD0E2FF),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/tooth-svgrepo-com.svg',
                          width: 32,
                          height: 32,
                          colorFilter: const ColorFilter.mode(
                            AppColors.azulPrimario,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (marcadas.isNotEmpty) ...[
                  const TituloSecao('Consultas do dia:'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      for (final agendamento in marcadas)
                        SizedBox(
                          width: 300,
                          child: CartaoConsulta(
                            consulta: agendamento,
                            onConfirmar: () => _confirmarAtendimento(agendamento),
                            onCancelar: () => _cancelarConsulta(agendamento),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
                TituloSecao(
                    tituloHorariosVagos(vagos.map((e) => e.horario).toList())),
                const SizedBox(height: 14),
                if (vagos.isEmpty)
                  const TextoVazio('Nenhum horário vago hoje.')
                else
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      for (final agendamento in vagos)
                        SizedBox(
                          width: 300,
                          child: CartaoConsulta(
                            consulta: agendamento,
                            onAgendar: () =>
                                _abrirDialogoAgendarPaciente(agendamento),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _saudacao() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textoEscuro,
        ),
        children: [
          const TextSpan(text: 'Olá, Dra. '),
          TextSpan(
            text: SessaoUsuario.nome ?? 'Dentista',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.azulPrimario,
            ),
          ),
        ],
      ),
    );
  }
}