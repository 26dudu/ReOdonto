import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../utils/avisos.dart';
import '../widgets/menu_navegacao.dart';
import '../widgets/pagina_com_menu.dart';
import '../widgets/perfil/campos_perfil.dart';
import '../widgets/perfil/grade_campos.dart';
import '../widgets/perfil/pilula_info.dart';
import '../widgets/secoes_texto.dart';
import 'telaLogin.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _EstadoTelaPerfil();
}

class _EstadoTelaPerfil extends State<TelaPerfil> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _cro = TextEditingController();

  double _avaliacao = 0;
  int _totalConsultas = 0;

  bool _carregando = true;
  bool _editando = false;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    for (final c in [_nome, _email, _telefone, _cro]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    if (SessaoUsuario.id == null) {
      setState(() {
        _carregando = false;
        _erro = 'Sessão inválida. Faça login novamente.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await ApiService.buscarPerfil(SessaoUsuario.id!);
    if (!mounted) return;

    if (resultado.temErro) {
      setState(() {
        _carregando = false;
        _erro = resultado.erro;
      });
      return;
    }

    final dados = resultado.dados!;
    setState(() {
      _carregando = false;
      _nome.text = dados['nome'] ?? '';
      _email.text = dados['email'] ?? '';
      _telefone.text = dados['telefone'] ?? '';
      _cro.text = dados['cro'] ?? '';
      _avaliacao = (dados['avaliacao'] as num?)?.toDouble() ?? 5.0;
      _totalConsultas = (dados['total_consultas'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> _salvarPerfil() async {
    if (_nome.text.trim().isEmpty) {
      return mostrarAviso(context, 'Nome não pode ser vazio', erro: true);
    }

    setState(() => _salvando = true);

    final resultado = await ApiService.atualizarPerfil(
      SessaoUsuario.id!,
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      telefone: _telefone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _salvando = false);

    if (resultado.temErro) {
      return mostrarAviso(context, resultado.erro!, erro: true);
    }

    // Atualiza a sessão local.
    await SessaoUsuario.salvar({
      'paciente': resultado.dados,
      'token': SessaoUsuario.token,
    });
    if (!mounted) return;

    setState(() => _editando = false);
    mostrarAviso(context, 'Perfil atualizado com sucesso!', sucesso: true);
  }

  void _cancelarEdicao() {
    setState(() => _editando = false);
    _carregarPerfil();
  }

  void _alternarEdicao() =>
      _editando ? _cancelarEdicao() : setState(() => _editando = true);

  Future<void> _logout() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair de sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (sair != true) return;

    await SessaoUsuario.limpar();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pronto = !_carregando && _erro == null;

    return PaginaComMenu(
      pagina: PaginaApp.perfil,
      carregando: _carregando,
      erro: _erro,
      onTentarNovamente: _carregarPerfil,
      // Desktop: título + botões no cabeçalho (o celular os põe no corpo).
      tituloDesktop: Text(
        _nome.text.isEmpty ? 'Meu Perfil' : _nome.text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textoEscuro,
        ),
      ),
      acoesDesktop: [
        if (pronto) ...[
          OutlinedButton.icon(
            icon: Icon(_editando ? Icons.close : Icons.edit),
            label: Text(_editando ? 'Cancelar' : 'Editar'),
            onPressed: _alternarEdicao,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 16),
        ],
      ],
      corpo: (celular) => _corpo(celular),
    );
  }

  Widget _corpo(bool celular) {
    Widget campo(String rotulo, TextEditingController c, {bool editavel = true}) =>
        CampoPerfil(
          rotulo: rotulo,
          controlador: c,
          somenteLeitura: !_editando || !editavel,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Celular: título + editar/sair aqui. Desktop: só o título.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TituloSecao(celular ? 'Seu perfil:' : 'Sua avaliação:'),
            if (celular)
              Row(children: [
                IconButton(
                  icon: Icon(_editando ? Icons.close : Icons.edit,
                      color: AppColors.azulPrimario),
                  onPressed: _alternarEdicao,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: _logout,
                ),
              ]),
          ],
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Row(
            children: [
              Expanded(
                child: PilulaInfo(
                  rotulo: 'Avaliação:',
                  valor: '${_avaliacao.toStringAsFixed(1)} ★',
                  rotuloClicavel: celular,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PilulaInfo(rotulo: 'Consultas:', valor: '$_totalConsultas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const TituloSecao('Dados Pessoais:'),
        const SizedBox(height: 14),
        GradeCampos(
          colunas: celular ? 1 : 2,
          filhos: [
            campo('Nome Completo:', _nome),
            campo('Email:', _email),
            campo('Telefone:', _telefone),
            campo('CRO:', _cro, editavel: false), // CRO não é editável
            const CampoEstatico(
              rotulo: 'Tipo de conta:',
              valor: 'Dentista',
              corValor: AppColors.azulPrimario,
            ),
          ],
        ),
        if (_editando) ...[
          const SizedBox(height: 24),
          _botoesEdicao(celular),
        ],
      ],
    );
  }

  /// Salvar + Cancelar: empilhados no celular, lado a lado no desktop.
  Widget _botoesEdicao(bool celular) {
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    final salvar = ElevatedButton(
      onPressed: _salvando ? null : _salvarPerfil,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.azulPrimario,
        minimumSize: const Size(0, 50),
        shape: forma,
      ),
      child: _salvando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text('Salvar Alterações',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );

    final cancelar = OutlinedButton(
      onPressed: _cancelarEdicao,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: forma),
      child: const Text('Cancelar'),
    );

    return celular
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [salvar, const SizedBox(height: 12), cancelar],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [cancelar, const SizedBox(width: 16), salvar],
          );
  }
}
