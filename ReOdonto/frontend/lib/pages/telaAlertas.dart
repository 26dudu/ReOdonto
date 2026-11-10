import 'package:flutter/material.dart';
import '../models/agendamento.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/avisos.dart';
import '../utils/formatadores.dart';
import '../widgets/agenda/cartao_consulta.dart';
import '../widgets/agenda/dialogo_agendar_paciente.dart';
import '../widgets/menu_navegacao.dart';
import '../widgets/pagina_com_menu.dart';
import '../widgets/secoes_texto.dart';

class TelaAlertas extends StatefulWidget {
  const TelaAlertas({super.key});

  @override
  State<TelaAlertas> createState() => _EstadoTelaAlertas();
}

class _EstadoTelaAlertas extends State<TelaAlertas> {
  List<Agendamento> _vagos = [];
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

    final agora = DateTime.now();
    final vagos = resultado.dados!
        .map((item) => Agendamento.fromJson(item as Map<String, dynamic>))
        .where((agendamento) => agendamento.vago && agendamento.dataHora != null && agendamento.dataHora!.isAfter(agora))
        .toList()
      ..sort((primeiro, segundo) => primeiro.dataHora!.compareTo(segundo.dataHora!));

    setState(() {
      _vagos = vagos;
      _carregando = false;
      _erro = null;
    });
  }

  Future<void> _encaixar(Agendamento vago) async {
    if (vago.id == null) return;

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

    setState(() => _vagos.removeWhere((agendamento) => agendamento.id == vago.id));
    mostrarAviso(context, 'Paciente encaixado com sucesso!');
  }

  @override
  Widget build(BuildContext context) {
    return PaginaComMenu(
      pagina: PaginaApp.alertas,
      carregando: _carregando,
      erro: _erro,
      onTentarNovamente: _carregar,
      onAtualizar: () => _carregar(silencioso: true),
      larguraMaxima: 720,
      acoesDesktop: [
        IconButton(
          tooltip: 'Atualizar alertas',
          onPressed: () => _carregar(silencioso: true),
          icon: const Icon(Icons.refresh, color: AppColors.textoEscuro),
        ),
      ],
      corpo: (_) => _conteudo(),
    );
  }

  Widget _conteudo() {
    final total = _vagos.length;
    final valorEmAberto = _vagos.fold<double>(0, (soma, agendamento) => soma + (agendamento.preco ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? 'Nenhum horário vago pela frente.'
              : '$total ${total == 1 ? 'horário vago' : 'horários vagos'} para encaixar'
                  '${valorEmAberto > 0 ? ' • ${formatarMoeda(valorEmAberto)} em jogo' : ''}',
          style: const TextStyle(fontSize: 14, color: AppColors.textoCinza),
        ),
        const SizedBox(height: 20),
        if (_vagos.isEmpty)
          const TextoVazio('Quando uma consulta for cancelada, o horário aparece aqui.')
        else
          for (final vago in _vagos) ...[
            TituloSecao(
              '${ehHoje(vago.dataHora!) ? 'Hoje' : formatarDataCurta(vago.dataHora!)}'
              ' às ${vago.horario}',
            ),
            const SizedBox(height: 8),
            CartaoConsulta(consulta: vago, onAgendar: () => _encaixar(vago)),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}
