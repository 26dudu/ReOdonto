import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/sessao_usuario.dart';
import '../../theme/app_colors.dart';
import '../../utils/mascaras.dart';
import 'cartao_resumo.dart';
import 'cartao_selecao.dart';
import 'calendario_personalizado.dart';
import 'input_horario.dart';

// =============================================================================
// Modal de Novo Agendamento
// Fluxo em 3 etapas: Dados do Paciente → Tipo de Consulta → Data/Hora
//
// Esse formulário é pro dentista cadastrar um paciente que chegou direto
// na clínica (ex: idosos que não usam o WhatsApp/app). Não pede clínica
// nem dentista pra selecionar: o app é de uso individual do dentista, ele
// já É a clínica/dentista logado — não faz sentido "escolher" isso.
//
// TODO(backend): `dentistaId` é lido de SessaoUsuario.id, assumindo que a
// sessão salva é a do dentista logado. Quando existir vínculo
// dentista→clínica no backend, ideal é o backend inferir a clínica a
// partir do dentista (ou do token JWT) em vez do app precisar informar.
// =============================================================================

class ModalNovoAgendamento extends StatefulWidget {
  final VoidCallback onAgendamentoCriado;
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
  Map<String, dynamic>? _consultaSelecionada;
  DateTime? _dataHoraSelecionada;
  TimeOfDay? _horarioSelecionado;
  final _controladorConsultaCustomizada = TextEditingController();
  bool _usandoConsultaCustomizada = false;

  // ---- listas carregadas da API ----
  List<dynamic> _consultas = [];

  // ---- controle de UI ----
  int _etapa = 0;
  bool _carregandoConsultas = false;
  bool _salvando = false;

  static const List<String> _titulosEtapa = [
    'Dados do Paciente',
    'Tipo de Consulta',
    'Data e Hora',
  ];

  @override
  void initState() {
    super.initState();
    _carregarConsultas();
  }

  @override
  void dispose() {
    _controladorNomePaciente.dispose();
    _controladorTelefonePaciente.dispose();
    _controladorConsultaCustomizada.dispose();
    super.dispose();
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

  void _avancar() {
    if (_etapa == 0 && !_chaveFormularioPaciente.currentState!.validate()) {
      return;
    }
    if (_etapa == 1) {
      if (_usandoConsultaCustomizada) {
        if (_controladorConsultaCustomizada.text.trim().isEmpty) {
          _mostrarErro('Informe o tipo de consulta customizado');
          return;
        }
      } else {
        if (_consultaSelecionada == null) {
          _mostrarErro('Selecione o tipo de consulta');
          return;
        }
      }
    }
    if (_etapa == 2) {
      if (_dataHoraSelecionada == null || _horarioSelecionado == null) {
        _mostrarErro('Selecione a data e horário');
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

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
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
      _mostrarErro('Sessão expirada. Faça login novamente.');
      return;
    }

    final r = await ApiService.criarAgendamento(
      dentistaId: dentistaId,
      consultaId: _usandoConsultaCustomizada ? null : _consultaSelecionada!['id'] as int,
      dataHora: iso,
      nomePaciente: _controladorNomePaciente.text.trim(),
      telefonePaciente: _controladorTelefonePaciente.text.trim(),
      consultaCustomizada: _usandoConsultaCustomizada ? _controladorConsultaCustomizada.text.trim() : null,
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
            child: Row(
              children: List.generate(3, (i) {
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _construirCorpoEtapa(),
            ),
          ),
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
                      _etapa < 2 ? 'Continuar' : 'Confirmar Agendamento',
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
        return _construirEtapaPaciente();
      case 1:
        return _construirEtapaConsulta();
      case 2:
        return _construirEtapaDataHora();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _construirEtapaPaciente() {
    return Form(
      key: _chaveFormularioPaciente,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paciente que chegou na clínica sem passar pelo WhatsApp/app.',
              style: TextStyle(fontSize: 13, color: AppColors.textoCinza),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controladorNomePaciente,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome do paciente'),
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'Informe o nome'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controladorTelefonePaciente,
              keyboardType: TextInputType.phone,
              inputFormatters: [TelefoneInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: '(DDD) 9XXXX-XXXX',
              ),
              validator: (valor) {
                final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
                if (digitos.length < 10) return 'Telefone inválido';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEtapaConsulta() {
    if (_carregandoConsultas) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione um tipo de consulta ou digite um customizado:',
            style: TextStyle(fontSize: 13, color: AppColors.textoCinza),
          ),
          const SizedBox(height: 16),
          if (_consultas.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _consultas.length,
              itemBuilder: (_, i) {
                final c = _consultas[i] as Map<String, dynamic>;
                final selecionado = !_usandoConsultaCustomizada && _consultaSelecionada?['id'] == c['id'];
                final valor = (c['valor'] as num?)?.toStringAsFixed(2) ?? '0.00';
                final duracao = c['duracao_minutos'] != null ? '${c['duracao_minutos']} min' : '';
                return CartaoSelecao(
                  titulo: c['nome'] ?? '',
                  subtitulo: 'R\$ $valor${duracao.isNotEmpty ? ' · $duracao' : ''}',
                  descricao: c['descricao'] as String?,
                  selecionado: selecionado,
                  onTap: () => setState(() {
                    _consultaSelecionada = c;
                    _usandoConsultaCustomizada = false;
                  }),
                );
              },
            ),
          if (_consultas.isNotEmpty) const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Ou digite um tipo de consulta customizado:',
            style: TextStyle(fontSize: 13, color: AppColors.textoCinza),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controladorConsultaCustomizada,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Tipo de consulta',
              hintText: 'Ex: Limpeza, Obturação, Extração',
              suffixIcon: _usandoConsultaCustomizada
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _controladorConsultaCustomizada.clear();
                        _usandoConsultaCustomizada = false;
                      }),
                    )
                  : null,
            ),
            onChanged: (valor) {
              setState(() {
                _usandoConsultaCustomizada = valor.trim().isNotEmpty;
                if (_usandoConsultaCustomizada) {
                  _consultaSelecionada = null;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _construirEtapaDataHora() {
    String dataFormatada = 'Nenhuma data selecionada';
    if (_dataHoraSelecionada != null && _horarioSelecionado != null) {
      final dt = _dataHoraSelecionada!;
      dataFormatada =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
          ' às ${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}';
    }

    final agora = DateTime.now();
    final dataFinal = agora.add(const Duration(days: 365));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CartaoResumo(
            paciente: _controladorNomePaciente.text,
            consulta: _usandoConsultaCustomizada
                ? _controladorConsultaCustomizada.text
                : _consultaSelecionada?['nome'] ?? '',
          ),
          const SizedBox(height: 24),
          CalendarioPersonalizado(
            dataInicial: agora.add(const Duration(days: 1)),
            dataFinal: dataFinal,
            dataSelecionada: _dataHoraSelecionada,
            onDataSelecionada: (data) => setState(() => _dataHoraSelecionada = data),
          ),
          const SizedBox(height: 24),
          InputHorario(
            horarioSelecionado: _horarioSelecionado,
            onHorarioSelecionado: (horario) => setState(() => _horarioSelecionado = horario),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dataHoraSelecionada != null && _horarioSelecionado != null
                  ? AppColors.azulClaro.withValues(alpha: 0.1)
                  : AppColors.bordaCampo.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dataFormatada,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _dataHoraSelecionada != null && _horarioSelecionado != null
                    ? AppColors.azulPrimario
                    : AppColors.textoCinza,
              ),
            ),
          ),
        ],
      ),
    );
  }
}