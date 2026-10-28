// Material Design.
import 'package:flutter/material.dart';
// Model Agendamento.
import '../models/agendamento.dart';
// Serviço da API (listar, cancelar, agendar).
import '../services/api_service.dart';
// Dados do usuário logado (nome).
import '../services/sessao_usuario.dart';
// Paleta de cores.
import '../theme/app_colors.dart';
// mostrarAviso.
import '../utils/avisos.dart';
// Funções de data (apenasData, mesmoDia, ehHoje, formatarDataCurta).
import '../utils/formatadores.dart';
// Pop-up para agendar um paciente num horário vago.
import '../widgets/agenda/dialogo_agendar_paciente.dart';
// Lista visual (timeline) dos agendamentos do dia.
import '../widgets/agenda/linha_do_tempo_agenda.dart';
// Modal (bottom sheet) para criar novo agendamento.
import '../widgets/agenda/modal_novo_agendamento.dart';
// Faixa semanal para escolher o dia.
import '../widgets/agenda/seletor_dia.dart';
// Enum PaginaApp.
import '../widgets/menu_navegacao.dart';
// Estrutura de página com menu.
import '../widgets/pagina_com_menu.dart';
// TituloSecao e TextoVazio.
import '../widgets/secoes_texto.dart';

// TELA DA AGENDA do dentista: mostra as consultas e horários vagos do dia escolhido.
class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _EstadoTelaAgenda();
}

class _EstadoTelaAgenda extends State<TelaAgenda> {
  // Lista com TODOS os agendamentos vindos da API (de todos os dias).
  List<Agendamento> _agendamentos = [];
  // true enquanto carrega pela primeira vez (ou ao tentar de novo).
  bool _carregando = true;
  // Mensagem de erro de carregamento (null = sem erro).
  String? _erro;

  // Dia exibido (só data, sem hora). Começa em hoje.
  // apenasData zera a hora para comparar só dia/mês/ano.
  DateTime _diaSelecionado = apenasData(DateTime.now());

  /// Agendamentos só do dia selecionado, ordenados por horário.
  // Getter calculado toda vez que é lido.
  List<Agendamento> get _agendamentosDoDia => _agendamentos
      // where filtra: só os que têm data válida e cujo dia é o selecionado.
      .where((a) => a.dataHora != null && mesmoDia(a.dataHora!, _diaSelecionado))
      // Converte o resultado do filtro em lista.
      .toList()
    // ".." (cascade) executa o sort na lista e devolve a própria lista.
    // Ordena pelo horário (compareTo devolve negativo/zero/positivo).
    ..sort((a, b) => a.dataHora!.compareTo(b.dataHora!));

  /// Dias com consulta marcada (bolinhas do SeletorDia). Vagos não contam.
  // Set = conjunto sem repetição. A sintaxe { for ... if ... } é uma "collection for/if".
  Set<DateTime> get _diasComConsulta => {
        for (final a in _agendamentos)
          // Só entram dias de agendamentos com data válida e que NÃO são horário vago.
          if (a.dataHora != null && !a.vago) apenasData(a.dataHora!),
      };

  @override
  // Ao abrir a tela, carrega os agendamentos.
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  /// [silencioso] = true (puxar-para-atualizar): mantém a lista na tela
  /// e, se falhar, só avisa num SnackBar. false: mostra o carregamento
  /// (primeira carga / "Tentar novamente").
  // Parâmetro nomeado opcional com valor padrão false.
  Future<void> _carregarAgendamentos({bool silencioso = false}) async {
    // No modo normal, mostra o indicador de carregamento e limpa o erro.
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    // Busca a lista na API.
    final resultado = await ApiService.listarAgendamentos();
    // Tela ainda existe?
    if (!mounted) return;

    // Tratamento de erro.
    if (resultado.temErro) {
      if (silencioso) {
        // Modo silencioso: mantém a lista e só avisa.
        mostrarAviso(context, resultado.erro!);
      } else {
        // Modo normal: troca a tela pelo estado de erro.
        setState(() {
          _carregando = false;
          _erro = resultado.erro;
        });
      }
      return;
    }

    // Sucesso: guarda a lista nova.
    setState(() {
      _carregando = false;
      _erro = null;
      // resultado.dados é uma lista de Maps (JSON); cada item vira um objeto Agendamento.
      _agendamentos = resultado.dados!
          .map((item) => Agendamento.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// Troca [antigo] por [novo] na lista (se ele ainda estiver lá).
  void _substituir(Agendamento antigo, Agendamento novo) {
    // indexWhere acha a posição do item com o mesmo id (-1 se não achar).
    final i = _agendamentos.indexWhere((a) => a.id == antigo.id);
    // Se achou, substitui naquela posição e redesenha.
    if (i != -1) setState(() => _agendamentos[i] = novo);
  }

  // Marca o atendimento como realizado na API (status "concluido").
  // Antes só mudava a tela: ao recarregar, a consulta voltava ao estado
  // anterior e o painel nunca contava a consulta como realizada.
  Future<void> _confirmarAtendimento(Agendamento a) async {
    if (a.id == null) return;

    final resultado = await ApiService.concluirAgendamento(a.id!);
    if (!mounted) return;

    if (resultado.temErro) return mostrarAviso(context, resultado.erro!);
    _substituir(a, Agendamento.fromJson(resultado.dados!));
    mostrarAviso(context, 'Atendimento confirmado.');
  }

  // Cancela a consulta. O backend abre um horário vago no mesmo lugar,
  // então a agenda é recarregada para ele aparecer pronto para um encaixe.
  // Antes o item só era removido da lista e o horário vago — razão de ser
  // do app — nunca surgia.
  Future<void> _cancelarConsulta(Agendamento a) async {
    // Sem id não há como cancelar.
    if (a.id == null) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cancelar consulta?'),
        content: Text(
          'A consulta de ${a.paciente ?? 'paciente'} às ${a.horario} será '
          'cancelada e o horário ficará vago para um encaixe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Cancelar consulta'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    final resultado = await ApiService.cancelarAgendamento(a.id!);
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

  // Abre o pop-up para preencher paciente e agenda num horário vago.
  Future<void> _abrirDialogoAgendarPaciente(Agendamento vago) async {
    // Sem id, o backend não sabe qual horário atualizar.
    if (vago.id == null) {
      return mostrarAviso(context, 'Não foi possível identificar esse horário.');
    }

    // O diálogo devolve um Map com 'nome' e 'telefone' (ou null se cancelado).
    final dados = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => DialogoAgendarPaciente(agendamento: vago),
    );
    // Se cancelou (null) ou a tela fechou, não faz nada.
    if (dados == null || !mounted) return;

    // Envia nome e telefone para a API agendar o paciente nesse horário.
    final resultado = await ApiService.agendarPacienteRapido(
      agendamentoId: vago.id!,
      nome: dados['nome']!,
      telefone: dados['telefone']!,
    );
    if (!mounted) return;

    if (resultado.temErro) return mostrarAviso(context, resultado.erro!);

    // Troca o horário vago pelo agendamento atualizado devolvido pela API.
    _substituir(vago, Agendamento.fromJson(resultado.dados!));
    mostrarAviso(context, 'Paciente agendado com sucesso!');
  }

  // Abre a folha inferior (bottom sheet) para criar um novo agendamento.
  void _novoAgendamento() {
    showModalBottomSheet(
      context: context,
      // Permite que a folha ocupe mais da tela (necessário com teclado).
      isScrollControlled: true,
      // Fundo transparente: o modal desenha seu próprio fundo arredondado.
      backgroundColor: Colors.transparent,
      builder: (_) => ModalNovoAgendamento(
        // Pula para o dia criado e recarrega, para o usuário vê-lo.
        // Callback chamado pelo modal quando o agendamento é criado com sucesso.
        onAgendamentoCriado: (dataCriada) {
          setState(() => _diaSelecionado = apenasData(dataCriada));
          _carregarAgendamentos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PaginaComMenu: esqueleto padrão com menu, carregando, erro e corpo.
    return PaginaComMenu(
      // Item "agenda" ativo no menu.
      pagina: PaginaApp.agenda,
      carregando: _carregando,
      erro: _erro,
      // Botão "Tentar novamente" recarrega no modo normal.
      onTentarNovamente: _carregarAgendamentos,
      // Puxar-para-atualizar recarrega no modo silencioso.
      onAtualizar: () => _carregarAgendamentos(silencioso: true),
      // Limita a largura do conteúdo em telas grandes.
      larguraMaxima: 720,
      // Desktop não tem "puxar para atualizar" com o mouse: damos um botão.
      acoesDesktop: [
        IconButton(
          tooltip: 'Atualizar agenda',
          onPressed: () => _carregarAgendamentos(silencioso: true),
          icon: const Icon(Icons.refresh, color: AppColors.textoEscuro),
        ),
      ],
      // Botão "+" flutuante no canto da tela para criar agendamento.
      botaoFlutuante: FloatingActionButton(
        onPressed: _novoAgendamento,
        backgroundColor: AppColors.azulPrimario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // O corpo recebe um parâmetro (celular ou não) que aqui é ignorado ("_").
      corpo: (_) => _conteudoDaAgenda(),
    );
  }

  // Monta o conteúdo principal da agenda.
  Widget _conteudoDaAgenda() {
    // Itens do dia selecionado (já ordenados).
    final itens = _agendamentosDoDia;
    // Quantos deles têm paciente (não são vagos).
    final marcadas = itens.where((a) => !a.vago).length;

    // Função local que escolhe singular/plural: plural(1,'consulta','consultas') → "1 consulta".
    String plural(int n, String singular, String plural) =>
        '$n ${n == 1 ? singular : plural}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da página.
        const Text(
          'Sua agenda',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 6),
        // Saudação com nome destacado em azul.
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textoEscuro,
            ),
            children: [
              const TextSpan(text: 'Olá, Dra. '),
              TextSpan(
                // Se o nome da sessão for null, usa 'Dentista'.
                text: SessaoUsuario.nome ?? 'Dentista',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulPrimario,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Faixa semanal: escolher o dia.
        SeletorDia(
          diaSelecionado: _diaSelecionado,
          // Dias que recebem a bolinha de "tem consulta".
          diasComConsulta: _diasComConsulta,
          // Ao escolher um dia, atualiza _diaSelecionado e redesenha.
          onDiaSelecionado: (dia) => setState(() => _diaSelecionado = dia),
        ),
        const SizedBox(height: 20),
        // Título muda: "Consultas de hoje" ou "Consultas de 28/09".
        TituloSecao(ehHoje(_diaSelecionado)
            ? 'Consultas de hoje'
            : 'Consultas de ${formatarDataCurta(_diaSelecionado)}'),
        const SizedBox(height: 4),
        // Resumo: "2 consultas • 1 horário vago".
        Text(
          // Duas strings literais vizinhas são concatenadas automaticamente pelo Dart.
          '${plural(marcadas, 'consulta', 'consultas')} • '
          '${plural(itens.length - marcadas, 'horário vago', 'horários vagos')}',
          style: const TextStyle(fontSize: 13, color: AppColors.textoCinza),
        ),
        const SizedBox(height: 14),
        // Se não há itens, mostra mensagem; senão mostra a linha do tempo.
        if (itens.isEmpty)
          const TextoVazio('Nenhuma consulta ou horário neste dia.')
        else
          LinhaDoTempoAgenda(
            itens: itens,
            // Callbacks para as ações de cada cartão.
            onConfirmar: _confirmarAtendimento,
            onCancelar: _cancelarConsulta,
            onAgendar: _abrirDialogoAgendarPaciente,
          ),
      ],
    );
  }
}
