import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_navegacao.dart';

// Cores de status específicas dessa tela — não fazem parte da paleta
// principal (AppColors), então ficam definidas localmente aqui.
const Color _corConfirmado = Color(0xFF1FAE7D);
const Color _corPendente = Color(0xFFF2994A);
const Color _corEstrela = Color(0xFFF2C94C);

/// Um horário da agenda do dentista para um dia.
///
/// Se [paciente] for nulo, o horário está vago — ninguém marcou consulta
/// ainda — e a tela mostra "Paciente: Indefinido", sem preço nem status.
/// Assim que alguém marcar (ou seja, [paciente] deixa de ser nulo), os
/// campos de avaliação/preço/status passam a fazer sentido e aparecem.
class _Agendamento {
  final int? id; // id do agendamento no backend — nulo enquanto mockado
  final String? paciente;
  final double? avaliacaoPaciente;
  final String dia;
  final String horario;
  final double? preco;
  final String? status; // 'Confirmado' ou 'Pendente'

  const _Agendamento({
    this.id,
    this.paciente,
    this.avaliacaoPaciente,
    required this.dia,
    required this.horario,
    this.preco,
    this.status,
  });

  bool get vago => paciente == null;

  _Agendamento copyWith({String? status}) => _Agendamento(
        id: id,
        paciente: paciente,
        avaliacaoPaciente: avaliacaoPaciente,
        dia: dia,
        horario: horario,
        preco: preco,
        status: status ?? this.status,
      );

  /// Mapeia um item da resposta de GET /agendamentos/ pro modelo da tela.
  ///
  /// ATENÇÃO: os nomes dos campos abaixo (`data_hora`, `paciente.nome`,
  /// `preco`, `status`...) são um palpite baseado no padrão do resto do
  /// [ApiService] (snake_case, como em `criarAgendamento`). Se o backend
  /// devolver nomes diferentes, é só ajustar aqui — o resto da tela não
  /// precisa mudar.
  factory _Agendamento.fromJson(Map<String, dynamic> json) {
    final paciente = json['paciente'] as Map<String, dynamic>?;
    final dataHora = DateTime.tryParse(json['data_hora']?.toString() ?? '');

    return _Agendamento(
      id: json['id'] as int?,
      paciente: paciente?['nome'] as String?,
      avaliacaoPaciente: (paciente?['avaliacao'] as num?)?.toDouble(),
      dia: dataHora == null
          ? ''
          : '${dataHora.day.toString().padLeft(2, '0')}/'
              '${dataHora.month.toString().padLeft(2, '0')}',
      horario: dataHora == null
          ? ''
          : '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}',
      preco: (json['preco'] as num?)?.toDouble(),
      status: _capitalizar(json['status'] as String?),
    );
  }
}

/// Deixa a primeira letra maiúscula ('confirmado' -> 'Confirmado').
/// A tela compara status com 'Confirmado'/'Pendente' — isso evita que a
/// comparação quebre se o backend devolver tudo em minúsculo (como faz
/// em `ApiService.cancelarAgendamento`, que manda 'cancelado').
String? _capitalizar(String? valor) {
  if (valor == null || valor.isEmpty) return valor;
  return valor[0].toUpperCase() + valor.substring(1).toLowerCase();
}

String _formatarPreco(double valor) {
  return 'R\$${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

/// Monta "Horários vagos: 20:00 e 21:30:" a partir da lista de horários
/// livres do dia — o texto se atualiza sozinho conforme a lista muda.
String _tituloHorariosVagos(List<String> horarios) {
  if (horarios.isEmpty) return 'Horários vagos:';
  if (horarios.length == 1) return 'Horários vagos: ${horarios.first}:';
  final inicio = horarios.sublist(0, horarios.length - 1).join(', ');
  return 'Horários vagos: $inicio e ${horarios.last}:';
}

/// Tela de Agenda do dentista — consultas do dia + horários ainda vagos.
/// Mobile: layout empilhado (menu hambúrguer + cards em coluna única).
/// Desktop/tablet: sidebar de navegação + cards em grade (Wrap).
///
/// As consultas marcadas vêm de GET /agendamentos/ (ver
/// [_Agendamento.fromJson]). Horários vagos ainda não têm rota no
/// backend, então continuam mockados em [_EstadoTelaAgenda._horariosVagos]
/// até essa rota existir.
class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _EstadoTelaAgenda();
}

class _EstadoTelaAgenda extends State<TelaAgenda> {
  static const double _quebraCelular = 700;

  // Consultas marcadas: agora vêm de verdade do backend.
  List<_Agendamento> _consultasMarcadas = [];
  bool _carregando = true;
  String? _erro;

  // TODO: ainda não existe rota no backend pra horários vagos —
  // continuam mockados até essa rota existir.
  final List<_Agendamento> _horariosVagos = const [
    _Agendamento(dia: '14/04', horario: '20:00'),
    _Agendamento(dia: '14/04', horario: '21:30'),
  ];

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
      _consultasMarcadas = resultado.dados!
          .map((item) => _Agendamento.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  void _confirmarAtendimento(int indice) {
    setState(() {
      _consultasMarcadas[indice] =
          _consultasMarcadas[indice].copyWith(status: 'Confirmado');
    });
    // TODO: chamar o backend aqui (ex.: PATCH /agendamentos/{id}/status)
    // quando essa rota existir — hoje o ApiService só tem cancelarAgendamento.
  }

  Future<void> _cancelarConsulta(int indice) async {
    final agendamento = _consultasMarcadas[indice];
    if (agendamento.id == null) return;

    final resultado = await ApiService.cancelarAgendamento(agendamento.id!);

    if (!mounted) return;

    if (resultado.temErro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado.erro!)),
      );
      return;
    }

    // Consulta cancelada no backend — remove da lista local.
    setState(() {
      _consultasMarcadas.removeAt(indice);
    });
  }

  void _procurarPacientes(_Agendamento agendamento) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Busca de pacientes ainda será implementada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      drawer: const MenuSanduiche(paginaAtiva: PaginaApp.agenda),
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

  // ------------------------------------------------------------------
  // MOBILE
  // ------------------------------------------------------------------
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
            const _TituloSecao('Consultas do dia:'),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < marcadas.length; i++) ...[
                  _CartaoConsulta(
                    consulta: marcadas[i],
                    onConfirmar: () => _confirmarAtendimento(i),
                    onCancelar: () => _cancelarConsulta(i),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          _TituloSecao(
              _tituloHorariosVagos(vagos.map((e) => e.horario).toList())),
          const SizedBox(height: 12),
          if (vagos.isEmpty)
            const _TextoVazio('Nenhum horário vago hoje.')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final agendamento in vagos) ...[
                  _CartaoConsulta(
                    consulta: agendamento,
                    onProcurarPacientes: () =>
                        _procurarPacientes(agendamento),
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

  // ------------------------------------------------------------------
  // DESKTOP
  // ------------------------------------------------------------------
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
                  const _TituloSecao('Consultas do dia:'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      for (int i = 0; i < marcadas.length; i++)
                        SizedBox(
                          width: 300,
                          child: _CartaoConsulta(
                            consulta: marcadas[i],
                            onConfirmar: () => _confirmarAtendimento(i),
                            onCancelar: () => _cancelarConsulta(i),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
                _TituloSecao(
                    _tituloHorariosVagos(vagos.map((e) => e.horario).toList())),
                const SizedBox(height: 14),
                if (vagos.isEmpty)
                  const _TextoVazio('Nenhum horário vago hoje.')
                else
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      for (final agendamento in vagos)
                        SizedBox(
                          width: 300,
                          child: _CartaoConsulta(
                            consulta: agendamento,
                            onProcurarPacientes: () =>
                                _procurarPacientes(agendamento),
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

  /// "Olá, Dra. [nome]" — usa o nome salvo em SessaoUsuario.
  /// TODO: SessaoUsuario hoje representa um paciente logado; quando
  /// existir uma sessão própria de dentista, trocar essa referência.
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

class _TituloSecao extends StatelessWidget {
  final String texto;
  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textoEscuro,
      ),
    );
  }
}

class _TextoVazio extends StatelessWidget {
  final String texto;
  const _TextoVazio(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: AppColors.textoCinza,
      ),
    );
  }
}

/// Card de um horário da agenda — muda de "forma" conforme [consulta]:
/// com paciente marcado (nome, avaliação, preço, status, botão de
/// confirmar/cancelar) ou vago (só dia/horário + botão de procurar
/// pacientes). Só um dos três callbacks é usado por vez — qual deles
/// depende do estado do [consulta] (vago / pendente / confirmado).
class _CartaoConsulta extends StatelessWidget {
  final _Agendamento consulta;
  final VoidCallback? onConfirmar;
  final VoidCallback? onCancelar;
  final VoidCallback? onProcurarPacientes;

  const _CartaoConsulta({
    required this.consulta,
    this.onConfirmar,
    this.onCancelar,
    this.onProcurarPacientes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fundoCartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordaCampo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linhaPaciente(),
          const SizedBox(height: 6),
          _linha('Dia:', consulta.dia),
          const SizedBox(height: 4),
          _linha('Horário:', consulta.horario),
          if (!consulta.vago) ...[
            const SizedBox(height: 4),
            _linha('Preço:', _formatarPreco(consulta.preco!)),
            const SizedBox(height: 4),
            _linhaStatus(),
          ],
          const SizedBox(height: 12),
          _botao(),
        ],
      ),
    );
  }

  Widget _linhaPaciente() {
    if (consulta.vago) {
      return const Text(
        'Paciente: Indefinido',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textoEscuro,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textoEscuro,
        ),
        children: [
          TextSpan(text: 'Paciente: ${consulta.paciente}'),
          if (consulta.avaliacaoPaciente != null)
            TextSpan(
              text:
                  ' ${consulta.avaliacaoPaciente!.toStringAsFixed(1).replaceAll('.', ',')} ★',
              style: const TextStyle(color: _corEstrela),
            ),
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
        children: [
          TextSpan(text: '$rotulo '),
          TextSpan(
            text: valor,
            style: const TextStyle(
              color: AppColors.textoEscuro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaStatus() {
    final cor = consulta.status == 'Confirmado' ? _corConfirmado : _corPendente;
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
        children: [
          const TextSpan(text: 'Status: '),
          TextSpan(
            text: consulta.status,
            style: TextStyle(color: cor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _botao() {
    final String texto;
    final VoidCallback? aoTocar;
    if (consulta.vago) {
      texto = 'Procurar Pacientes';
      aoTocar = onProcurarPacientes;
    } else if (consulta.status == 'Pendente') {
      texto = 'Confirmar Atendimento';
      aoTocar = onConfirmar;
    } else {
      texto = 'Deseja Cancelar?';
      aoTocar = onCancelar;
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulPrimario,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}