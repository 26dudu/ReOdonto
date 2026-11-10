import 'package:flutter/material.dart';
import '../models/agendamento.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../utils/avisos.dart';
import '../utils/dialogos.dart';
import '../utils/formatadores.dart';
import '../widgets/agenda/cabecalho_agenda.dart';
import '../widgets/agenda/dialogo_agendar_paciente.dart';
import '../widgets/agenda/linha_do_tempo_agenda.dart';
import '../widgets/agenda/modal_novo_agendamento.dart';
import '../widgets/agenda/seletor_dia.dart';
import '../widgets/menu_navegacao.dart';
import '../widgets/pagina_com_menu.dart';
import '../widgets/secoes_texto.dart';

class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _EstadoTelaAgenda();
}

class _EstadoTelaAgenda extends State<TelaAgenda> {
  List<Agendamento> _agendamentos = [];
  bool _carregando = true;
  String? _erro;

  DateTime _diaSelecionado = apenasData(DateTime.now());

  List<Agendamento> get _agendamentosDoDia => _agendamentos
      .where((agendamento) => agendamento.dataHora != null && mesmoDia(agendamento.dataHora!, _diaSelecionado))
      .toList()
    ..sort((primeiro, segundo) => primeiro.dataHora!.compareTo(segundo.dataHora!));

  Set<DateTime> get _diasComConsulta => {
        for (final agendamento in _agendamentos)
          if (agendamento.dataHora != null && !agendamento.vago) apenasData(agendamento.dataHora!),
      };

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    final resultado = await ApiService.listarAgendamentos();
    if (!mounted) return;

    if (resultado.temErro) {
      if (silencioso) {
        mostrarAviso(context, resultado.erro!);
      } else {
        setState(() {
          _carregando = false;
          _erro = resultado.erro;
        });
      }
      return;
    }

    setState(() {
      _carregando = false;
      _erro = null;
      _agendamentos = resultado.dados!
          .map((item) => Agendamento.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  void _substituir(Agendamento antigo, Agendamento novo) {
    final posicaoNaLista = _agendamentos.indexWhere((agendamento) => agendamento.id == antigo.id);
    if (posicaoNaLista != -1) setState(() => _agendamentos[posicaoNaLista] = novo);
  }

  Future<void> _confirmarAtendimento(Agendamento agendamento) async {
    if (agendamento.id == null) return;

    final resultado = await ApiService.concluirAgendamento(agendamento.id!);
    if (!mounted) return;

    if (resultado.temErro) return mostrarAviso(context, resultado.erro!);
    _substituir(agendamento, Agendamento.fromJson(resultado.dados!));
    mostrarAviso(context, 'Atendimento confirmado.');
  }

  Future<void> _cancelarConsulta(Agendamento agendamento) async {
    if (agendamento.id == null) return;

    final confirmou = await confirmarAcao(
      context,
      titulo: 'Cancelar consulta?',
      mensagem: 'A consulta de ${agendamento.paciente ?? 'paciente'} às ${agendamento.horario} será '
          'cancelada e o horário ficará vago para um encaixe.',
      textoConfirmar: 'Cancelar consulta',
      textoVoltar: 'Voltar',
    );
    if (confirmou != true || !mounted) return;

    final resultado = await ApiService.cancelarAgendamento(agendamento.id!);
    if (!mounted) return;

    if (resultado.temErro) return mostrarAviso(context, resultado.erro!);

    await _carregarAgendamentos(silencioso: true);
    if (!mounted) return;
    mostrarAviso(
      context,
      resultado.dados?['horario_liberado'] != null
          ? 'Consulta cancelada. O horário ficou vago para um encaixe.'
          : 'Consulta cancelada.',
    );
  }

  Future<void> _abrirDialogoAgendarPaciente(Agendamento vago) async {
    if (vago.id == null) {
      return mostrarAviso(context, 'Não foi possível identificar esse horário.');
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

    if (resultado.temErro) return mostrarAviso(context, resultado.erro!);

    _substituir(vago, Agendamento.fromJson(resultado.dados!));
    mostrarAviso(context, 'Paciente agendado com sucesso!');
  }

  void _novoAgendamento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModalNovoAgendamento(
        onAgendamentoCriado: (dataCriada) {
          setState(() => _diaSelecionado = apenasData(dataCriada));
          _carregarAgendamentos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaginaComMenu(
      pagina: PaginaApp.agenda,
      carregando: _carregando,
      erro: _erro,
      onTentarNovamente: _carregarAgendamentos,
      onAtualizar: () => _carregarAgendamentos(silencioso: true),
      larguraMaxima: 720,
      acoesDesktop: [
        IconButton(
          tooltip: 'Atualizar agenda',
          onPressed: () => _carregarAgendamentos(silencioso: true),
          icon: const Icon(Icons.refresh, color: AppColors.textoEscuro),
        ),
      ],
      botaoFlutuante: FloatingActionButton(
        onPressed: _novoAgendamento,
        backgroundColor: AppColors.azulPrimario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      corpo: (_) => _conteudoDaAgenda(),
    );
  }

  Widget _conteudoDaAgenda() {
    final itens = _agendamentosDoDia;
    final marcadas = itens.where((agendamento) => !agendamento.vago).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CabecalhoAgenda(nomeDentista: SessaoUsuario.nome),
        const SizedBox(height: 20),
        SeletorDia(
          diaSelecionado: _diaSelecionado,
          diasComConsulta: _diasComConsulta,
          onDiaSelecionado: (dia) => setState(() => _diaSelecionado = dia),
        ),
        const SizedBox(height: 20),
        TituloSecao(ehHoje(_diaSelecionado)
            ? 'Consultas de hoje'
            : 'Consultas de ${formatarDataCurta(_diaSelecionado)}'),
        const SizedBox(height: 4),
        Text(
          '${pluralizar(marcadas, 'consulta', 'consultas')} • '
          '${pluralizar(itens.length - marcadas, 'horário vago', 'horários vagos')}',
          style: const TextStyle(fontSize: 13, color: AppColors.textoCinza),
        ),
        const SizedBox(height: 14),
        if (itens.isEmpty)
          const TextoVazio('Nenhuma consulta ou horário neste dia.')
        else
          LinhaDoTempoAgenda(
            itens: itens,
            onConfirmar: _confirmarAtendimento,
            onCancelar: _cancelarConsulta,
            onAgendar: _abrirDialogoAgendarPaciente,
          ),
      ],
    );
  }
}
