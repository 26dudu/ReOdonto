import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_navegacao.dart';

class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _EstadoTelaAgenda();
}

class _EstadoTelaAgenda extends State<TelaAgenda> {
  static const double _quebraCelular = 700;

  List<dynamic> _agendamentos = [];
  bool _carregando = true;
  String? _erro;

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
      _agendamentos = resultado.dados ?? [];
    });
  }

  Future<void> _cancelarAgendamento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text('Tem certeza que deseja cancelar esta consulta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, cancelar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _carregando = true);

    final resultado = await ApiService.cancelarAgendamento(id);

    if (!mounted) return;

    if (resultado.temErro) {
      _mostrarErro(resultado.erro!);
      _carregarAgendamentos();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Agendamento cancelado com sucesso.'),
        backgroundColor: Colors.green,
      ),
    );

    _carregarAgendamentos();
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _novoAgendamento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalNovoAgendamento(
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
        child: LayoutBuilder(
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

  Widget _construirLayoutCelular() {
    return RefreshIndicator(
      onRefresh: _carregarAgendamentos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    border: Border.all(color: const Color(0xFFD0E2FF), width: 2),
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
            const SizedBox(height: 24),
            const Text(
              'Meus Agendamentos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textoEscuro,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Olá, ${SessaoUsuario.nome ?? "Paciente"}! Veja abaixo seus horários marcados.',
              style: const TextStyle(fontSize: 14, color: AppColors.textoCinza),
            ),
            const SizedBox(height: 20),
            if (_carregando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_erro != null)
              _construirErroWidget()
            else if (_agendamentos.isEmpty)
              _construirListaVazia()
            else
              Column(
                children: [
                  for (final item in _agendamentos) ...[
                    _CartaoAgendamentoPaciente(
                      agendamento: item as Map<String, dynamic>,
                      onCancelar: () => _cancelarAgendamento(item['id'] as int),
                    ),
                    const SizedBox(height: 14),
                  ]
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _construirLayoutDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BarraLateralMenu(paginaAtiva: PaginaApp.agenda),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregarAgendamentos,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Meus Agendamentos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textoEscuro,
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
                  const SizedBox(height: 10),
                  Text(
                    'Olá, ${SessaoUsuario.nome ?? "Paciente"}! Veja abaixo seus horários marcados.',
                    style: const TextStyle(fontSize: 15, color: AppColors.textoCinza),
                  ),
                  const SizedBox(height: 28),
                  if (_carregando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_erro != null)
                    _construirErroWidget()
                  else if (_agendamentos.isEmpty)
                    _construirListaVazia()
                  else
                    Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      children: [
                        for (final item in _agendamentos)
                          SizedBox(
                            width: 320,
                            child: _CartaoAgendamentoPaciente(
                              agendamento: item as Map<String, dynamic>,
                              onCancelar: () => _cancelarAgendamento(item['id'] as int),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirErroWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Erro: $_erro', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _carregarAgendamentos,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _construirListaVazia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 54, color: AppColors.textoCinza),
            const SizedBox(height: 16),
            const Text(
              'Você não tem agendamentos ainda.',
              style: TextStyle(fontSize: 16, color: AppColors.textoCinza, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _novoAgendamento,
              icon: const Icon(Icons.add),
              label: const Text('Agendar consulta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoAgendamentoPaciente extends StatelessWidget {
  final Map<String, dynamic> agendamento;
  final VoidCallback onCancelar;

  const _CartaoAgendamentoPaciente({
    required this.agendamento,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final String status = agendamento['status'] ?? 'agendado';
    final String dataHoraRaw = agendamento['data_hora'] ?? '';
    final String dentista = agendamento['dentista_nome'] ?? 'Dentista';
    final String clinica = agendamento['clinica_nome'] ?? 'Clínica';
    final String consulta = agendamento['consulta_nome'] ?? 'Consulta';

    // Format DateTime nicely
    String dataExibicao = dataHoraRaw;
    try {
      final dt = DateTime.parse(dataHoraRaw);
      dataExibicao =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    Color corStatus;
    switch (status.toLowerCase()) {
      case 'agendado':
        corStatus = Colors.blue;
        break;
      case 'concluido':
        corStatus = Colors.green;
        break;
      case 'cancelado':
        corStatus = Colors.red;
        break;
      default:
        corStatus = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordaCampo),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  consulta,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoEscuro,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: corStatus.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: corStatus,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.person_outline, 'Dentista:', dentista),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.business_outlined, 'Clínica:', clinica),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time_outlined, 'Horário:', dataExibicao),
          if (status.toLowerCase() == 'agendado') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancelar,
                icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                label: const Text(
                  'Cancelar Agendamento',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textoCinza),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textoCinza,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textoEscuro,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Modal de Novo Agendamento
// Fluxo em 4 etapas: Clínica → Dentista → Consulta → Data/Hora
// =============================================================================

class _ModalNovoAgendamento extends StatefulWidget {
  final VoidCallback onAgendamentoCriado;
  const _ModalNovoAgendamento({required this.onAgendamentoCriado});

  @override
  State<_ModalNovoAgendamento> createState() => _EstadoModalNovoAgendamento();
}

class _EstadoModalNovoAgendamento extends State<_ModalNovoAgendamento> {
  // ---- estado da seleção ----
  Map<String, dynamic>? _clinicaSelecionada;
  Map<String, dynamic>? _dentistaSelecionado;
  Map<String, dynamic>? _consultaSelecionada;
  DateTime? _dataHoraSelecionada;

  // ---- listas carregadas da API ----
  List<dynamic> _clinicas = [];
  List<dynamic> _dentistas = [];
  List<dynamic> _consultas = [];

  // ---- controle de UI ----
  int _etapa = 0; // 0=clínica, 1=dentista, 2=consulta, 3=data/hora, 4=confirmando
  bool _carregandoClinicas = true;
  bool _carregandoDentistas = false;
  bool _carregandoConsultas = false;
  bool _salvando = false;
  String? _erro;

  static const List<String> _titulosEtapa = [
    'Selecionar Clínica',
    'Selecionar Dentista',
    'Tipo de Consulta',
    'Data e Hora',
  ];

  @override
  void initState() {
    super.initState();
    _carregarClinicas();
    _carregarConsultas();
  }

  // ---- carregamentos ----

  Future<void> _carregarClinicas() async {
    setState(() => _carregandoClinicas = true);
    final r = await ApiService.listarClinicas(perPage: 100);
    if (!mounted) return;
    setState(() {
      _carregandoClinicas = false;
      if (!r.temErro) _clinicas = (r.dados?['clinicas'] as List<dynamic>?) ?? [];
    });
  }

  Future<void> _carregarDentistas(int clinicaId) async {
    setState(() {
      _carregandoDentistas = true;
      _dentistas = [];
      _dentistaSelecionado = null;
    });
    final r = await ApiService.listarDentistas(clinicaId: clinicaId);
    if (!mounted) return;
    setState(() {
      _carregandoDentistas = false;
      if (!r.temErro) _dentistas = r.dados ?? [];
    });
  }

  Future<void> _carregarConsultas() async {
    setState(() => _carregandoConsultas = true);
    final r = await ApiService.listarConsultas();
    if (!mounted) return;
    setState(() {
      _carregandoConsultas = false;
      if (!r.temErro) _consultas = r.dados ?? [];
    });
  }

  // ---- navegação entre etapas ----

  void _avancar() {
    if (_etapa == 0 && _clinicaSelecionada == null) {
      _mostrarErro('Selecione uma clínica');
      return;
    }
    if (_etapa == 1 && _dentistaSelecionado == null) {
      _mostrarErro('Selecione um dentista');
      return;
    }
    if (_etapa == 2 && _consultaSelecionada == null) {
      _mostrarErro('Selecione o tipo de consulta');
      return;
    }
    if (_etapa == 3 && _dataHoraSelecionada == null) {
      _mostrarErro('Selecione a data e horário');
      return;
    }
    if (_etapa < 3) {
      setState(() => _etapa++);
    } else {
      _confirmarAgendamento();
    }
  }

  void _voltar() {
    if (_etapa > 0) setState(() => _etapa--);
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ---- picker de data/hora ----

  Future<void> _escolherDataHora() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: agora.add(const Duration(days: 1)),
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (hora == null || !mounted) return;

    final dataHora = DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    if (dataHora.isBefore(DateTime.now())) {
      _mostrarErro('A data/hora não pode ser no passado');
      return;
    }
    setState(() => _dataHoraSelecionada = dataHora);
  }

  // ---- confirmar na API ----

  Future<void> _confirmarAgendamento() async {
    setState(() => _salvando = true);

    // Formata para ISO 8601 sem fuso (backend espera datetime local)
    final iso = _dataHoraSelecionada!.toIso8601String().substring(0, 19);

    final r = await ApiService.criarAgendamento(
      dentistaId: _dentistaSelecionado!['id'] as int,
      consultaId: _consultaSelecionada!['id'] as int,
      clinicaId: _clinicaSelecionada!['id'] as int,
      dataHora: iso,
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    if (r.temErro) {
      _mostrarErro(r.erro!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Agendamento criado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
    widget.onAgendamentoCriado();
  }

  // ---- build principal ----

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * 0.85;
    return Container(
      height: altura,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // alça visual
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.bordaCampo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                if (_etapa > 0)
                  IconButton(
                    onPressed: _voltar,
                    icon: const Icon(Icons.arrow_back, color: AppColors.textoEscuro),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (_etapa > 0) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _titulosEtapa[_etapa],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoEscuro,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textoCinza),
                ),
              ],
            ),
          ),
          // indicador de etapa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(4, (i) {
                final ativo = i == _etapa;
                final concluido = i < _etapa;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: concluido
                          ? Colors.green
                          : ativo
                              ? AppColors.azulPrimario
                              : AppColors.bordaCampo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          // corpo da etapa
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _construirCorpoEtapa(),
            ),
          ),
          // botão de avançar
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: ElevatedButton(
              onPressed: _salvando ? null : _avancar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      _etapa < 3 ? 'Continuar' : 'Confirmar Agendamento',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCorpoEtapa() {
    switch (_etapa) {
      case 0:
        return _construirEtapaClinica();
      case 1:
        return _construirEtapaDentista();
      case 2:
        return _construirEtapaConsulta();
      case 3:
        return _construirEtapaDataHora();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- Etapa 0 — Clínica ----

  Widget _construirEtapaClinica() {
    if (_carregandoClinicas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_clinicas.isEmpty) {
      return const Center(
        child: Text('Nenhuma clínica disponível no momento.', textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      itemCount: _clinicas.length,
      itemBuilder: (_, i) {
        final c = _clinicas[i] as Map<String, dynamic>;
        final selecionado = _clinicaSelecionada?['id'] == c['id'];
        return _CartaoSelecao(
          titulo: c['nome'] ?? '',
          subtitulo: _enderecoClinica(c),
          selecionado: selecionado,
          onTap: () {
            setState(() => _clinicaSelecionada = c);
            _carregarDentistas(c['id'] as int);
          },
        );
      },
    );
  }

  String _enderecoClinica(Map<String, dynamic> c) {
    final partes = <String>[];
    if ((c['rua'] ?? '').isNotEmpty) partes.add(c['rua'] as String);
    if ((c['bairro'] ?? '').isNotEmpty) partes.add(c['bairro'] as String);
    if ((c['cidade'] ?? '').isNotEmpty) partes.add(c['cidade'] as String);
    return partes.join(', ');
  }

  // ---- Etapa 1 — Dentista ----

  Widget _construirEtapaDentista() {
    if (_carregandoDentistas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dentistas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum dentista encontrado para esta clínica.\nTente outra clínica.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _dentistas.length,
      itemBuilder: (_, i) {
        final d = _dentistas[i] as Map<String, dynamic>;
        final selecionado = _dentistaSelecionado?['id'] == d['id'];
        return _CartaoSelecao(
          titulo: d['nome'] ?? '',
          subtitulo: d['cro'] != null ? 'CRO: ${d['cro']}' : '',
          selecionado: selecionado,
          onTap: () => setState(() => _dentistaSelecionado = d),
        );
      },
    );
  }

  // ---- Etapa 2 — Consulta ----

  Widget _construirEtapaConsulta() {
    if (_carregandoConsultas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_consultas.isEmpty) {
      return const Center(child: Text('Nenhum tipo de consulta disponível.'));
    }
    return ListView.builder(
      itemCount: _consultas.length,
      itemBuilder: (_, i) {
        final c = _consultas[i] as Map<String, dynamic>;
        final selecionado = _consultaSelecionada?['id'] == c['id'];
        final valor = (c['valor'] as num?)?.toStringAsFixed(2) ?? '0.00';
        final duracao = c['duracao_minutos'] != null ? '${c['duracao_minutos']} min' : '';
        return _CartaoSelecao(
          titulo: c['nome'] ?? '',
          subtitulo: 'R\$ $valor${duracao.isNotEmpty ? ' · $duracao' : ''}',
          descricao: c['descricao'] as String?,
          selecionado: selecionado,
          onTap: () => setState(() => _consultaSelecionada = c),
        );
      },
    );
  }

  // ---- Etapa 3 — Data e Hora ----

  Widget _construirEtapaDataHora() {
    String dataFormatada = 'Nenhuma data selecionada';
    if (_dataHoraSelecionada != null) {
      final dt = _dataHoraSelecionada!;
      dataFormatada =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
          ' às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // resumo do que foi selecionado
        _CartaoResumo(
          clinica: _clinicaSelecionada?['nome'] ?? '',
          dentista: _dentistaSelecionado?['nome'] ?? '',
          consulta: _consultaSelecionada?['nome'] ?? '',
        ),
        const SizedBox(height: 24),
        const Text(
          'Data e Horário',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textoEscuro),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _escolherDataHora,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.preenchimentoCampo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _dataHoraSelecionada != null ? AppColors.azulPrimario : AppColors.bordaCampo,
                width: _dataHoraSelecionada != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: _dataHoraSelecionada != null ? AppColors.azulPrimario : AppColors.textoCinza,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dataFormatada,
                    style: TextStyle(
                      fontSize: 14,
                      color: _dataHoraSelecionada != null
                          ? AppColors.textoEscuro
                          : AppColors.textoCinza,
                      fontWeight: _dataHoraSelecionada != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.textoCinza),
              ],
            ),
          ),
        ),
        if (_dataHoraSelecionada != null) ...[
          const SizedBox(height: 8),
          Text(
            'Toque para alterar a data ou horário.',
            style: TextStyle(fontSize: 12, color: AppColors.textoCinza),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Widgets auxiliares do modal
// =============================================================================

class _CartaoSelecao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String? descricao;
  final bool selecionado;
  final VoidCallback onTap;

  const _CartaoSelecao({
    required this.titulo,
    required this.subtitulo,
    this.descricao,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado
              ? AppColors.azulPrimario.withOpacity(0.08)
              : AppColors.preenchimentoCampo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? AppColors.azulPrimario : AppColors.bordaCampo,
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selecionado ? AppColors.azulPrimario : AppColors.textoEscuro,
                    ),
                  ),
                  if (subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
                    ),
                  ],
                  if (descricao != null && descricao!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      descricao!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selecionado ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selecionado ? AppColors.azulPrimario : AppColors.bordaCampo,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoResumo extends StatelessWidget {
  final String clinica;
  final String dentista;
  final String consulta;

  const _CartaoResumo({
    required this.clinica,
    required this.dentista,
    required this.consulta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.preenchimentoCampo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordaCampo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo da consulta',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textoCinza,
            ),
          ),
          const SizedBox(height: 10),
          _LinhaResumo(icone: Icons.business_outlined, label: 'Clínica', valor: clinica),
          const SizedBox(height: 6),
          _LinhaResumo(icone: Icons.person_outline, label: 'Dentista', valor: dentista),
          const SizedBox(height: 6),
          _LinhaResumo(icone: Icons.medical_services_outlined, label: 'Consulta', valor: consulta),
        ],
      ),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;

  const _LinhaResumo({
    required this.icone,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: AppColors.textoCinza),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textoCinza,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 12, color: AppColors.textoEscuro),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
