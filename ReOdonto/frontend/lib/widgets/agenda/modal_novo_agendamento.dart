import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/sessao_usuario.dart';
import '../../theme/app_colors.dart';
import 'indicador_progresso.dart';
import 'etapa_paciente.dart';
import 'etapa_consulta.dart';
import 'etapa_data_hora.dart';
import '../../utils/avisos.dart';
import '../botao_principal.dart';

// =============================================================================
// Modal de Novo Agendamento
//
// Fluxo em 3 etapas: Dados do Paciente → Tipo de Consulta → Data/Hora
//
// Esse formulário é pro dentista cadastrar um paciente que chegou direto
// na clínica (ex: idosos que não usam o WhatsApp/app). Não pede clínica
// nem dentista pra selecionar: o app é de uso individual do dentista, ele
// já É a clínica/dentista logado — não faz sentido "escolher" isso.
//
// Cada etapa vive em seu próprio widget (etapa_paciente.dart,
// etapa_consulta.dart, etapa_data_hora.dart). Este arquivo cuida só do
// estado compartilhado e da lógica de navegação/confirmação.
//
// O backend sempre usa o dentista do token JWT; `dentistaId` vai no corpo
// só por compatibilidade e é ignorado lá.
//
// Com "Abrir horário vago" ligado na primeira etapa, o horário é criado
// sem paciente e aparece na agenda pronto para um encaixe.
// =============================================================================

class ModalNovoAgendamento extends StatefulWidget {
  // Entrega a data do agendamento criado, para a telaAgenda pular para esse dia.
  final ValueChanged<DateTime> onAgendamentoCriado;
  const ModalNovoAgendamento({super.key, required this.onAgendamentoCriado});

  @override
  State<ModalNovoAgendamento> createState() => _EstadoModalNovoAgendamento();
}

class _EstadoModalNovoAgendamento extends State<ModalNovoAgendamento> {
  // ---- dados do paciente (cadastro rápido, sem conta) ----
  final _chaveFormularioPaciente = GlobalKey<FormState>();
  final _controladorNomePaciente = TextEditingController();
  final _controladorTelefonePaciente = TextEditingController();

  // ---- estado da seleção ----
  DateTime? _dataHoraSelecionada;
  TimeOfDay? _horarioSelecionado;
  final _controladorConsultaCustomizada = TextEditingController();
  final _controladorValor = TextEditingController();
  final _controladorDuracao = TextEditingController(text: '30');

  // true = cria um horário vago, sem paciente, pronto para um encaixe.
  bool _horarioVago = false;

  // ---- controle de UI ----
  int _etapa = 0;
  bool _salvando = false;

  static const List<String> _titulosEtapa = [
    'Dados do Paciente',
    'Tipo de Consulta',
    'Data e Hora',
  ];

  @override
  void dispose() {
    _controladorNomePaciente.dispose();
    _controladorTelefonePaciente.dispose();
    _controladorConsultaCustomizada.dispose();
    _controladorValor.dispose();
    _controladorDuracao.dispose();
    super.dispose();
  }

  void _avancar() {
    if (_etapa == 0 && !_chaveFormularioPaciente.currentState!.validate()) {
      return;
    }
    if (_etapa == 1) {
      if (!_horarioVago && _controladorConsultaCustomizada.text.trim().isEmpty) {
        mostrarAviso(context, 'Informe o tipo de consulta', erro: true);
        return;
      }
      if (_controladorValor.text.trim().isNotEmpty &&
          lerValorEmReais(_controladorValor.text) == null) {
        mostrarAviso(context, 'Valor inválido. Use, por exemplo, 200,00', erro: true);
        return;
      }
      final duracao = int.tryParse(_controladorDuracao.text.trim());
      if (duracao == null || duracao <= 0) {
        mostrarAviso(context, 'Informe a duração em minutos', erro: true);
        return;
      }
    }
    if (_etapa == 2) {
      if (_dataHoraSelecionada == null || _horarioSelecionado == null) {
        mostrarAviso(context, 'Selecione a data e horário', erro: true);
        return;
      }
    }
    if (_etapa < 2) {
      setState(() => _etapa++);
    } else {
      _confirmarAgendamento();
    }
  }

  void _voltar() {
    if (_etapa > 0) setState(() => _etapa--);
  }


  Future<void> _confirmarAgendamento() async {
    setState(() => _salvando = true);

    // Combina a data selecionada com o horário
    final dataComHora = DateTime(
      _dataHoraSelecionada!.year,
      _dataHoraSelecionada!.month,
      _dataHoraSelecionada!.day,
      _horarioSelecionado!.hour,
      _horarioSelecionado!.minute,
    );
    final iso = dataComHora.toIso8601String().substring(0, 19);

    // Dentista logado — vem da sessão. O app não pede pra selecionar
    // porque cada dentista só enxerga e mexe na própria agenda.
    final dentistaId = SessaoUsuario.id;
    if (dentistaId == null) {
      setState(() => _salvando = false);
      mostrarAviso(context, 'Sessão expirada. Faça login novamente.', erro: true);
      return;
    }

    final consulta = _controladorConsultaCustomizada.text.trim();
    final r = await ApiService.criarAgendamento(
      dentistaId: dentistaId,
      dataHora: iso,
      // Sem nome o backend cria um horário vago.
      nomePaciente: _horarioVago ? null : _controladorNomePaciente.text.trim(),
      telefonePaciente:
          _horarioVago ? null : _controladorTelefonePaciente.text.trim(),
      consultaCustomizada: consulta.isEmpty ? null : consulta,
      valor: lerValorEmReais(_controladorValor.text),
      duracaoMinutos: int.tryParse(_controladorDuracao.text.trim()),
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    if (r.temErro) {
      mostrarAviso(context, r.erro!, erro: true);
      return;
    }

    mostrarAviso(
      context,
      _horarioVago ? 'Horário vago aberto na agenda!' : 'Agendamento criado com sucesso!',
      sucesso: true,
    );
    Navigator.pop(context);
    widget.onAgendamentoCriado(dataComHora);
  }

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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.bordaCampo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: IndicadorProgresso(etapaAtual: _etapa),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _construirCorpoEtapa(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: BotaoPrincipal(
              texto: _etapa < 2 ? 'Continuar' : 'Confirmar Agendamento',
              carregando: _salvando,
              onPressed: _salvando ? null : _avancar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCorpoEtapa() {
    switch (_etapa) {
      case 0:
        return EtapaPaciente(
          chaveFormulario: _chaveFormularioPaciente,
          controladorNome: _controladorNomePaciente,
          controladorTelefone: _controladorTelefonePaciente,
          horarioVago: _horarioVago,
          onHorarioVagoAlterado: (valor) => setState(() => _horarioVago = valor),
        );
      case 1:
        return EtapaConsulta(
          controlador: _controladorConsultaCustomizada,
          controladorValor: _controladorValor,
          controladorDuracao: _controladorDuracao,
          tipoOpcional: _horarioVago,
        );
      case 2:
        return EtapaDataHora(
          nomePaciente: _horarioVago ? 'Horário vago' : _controladorNomePaciente.text,
          tipoConsulta: _controladorConsultaCustomizada.text.trim(),
          dataSelecionada: _dataHoraSelecionada,
          horarioSelecionado: _horarioSelecionado,
          onDataSelecionada: (data) => setState(() => _dataHoraSelecionada = data),
          onHorarioSelecionado: (horario) => setState(() => _horarioSelecionado = horario),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}