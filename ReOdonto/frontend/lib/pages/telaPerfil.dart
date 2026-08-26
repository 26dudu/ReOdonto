import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/sessao_usuario.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_navegacao.dart';
import 'telaLogin.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _EstadoTelaPerfil();
}

class _EstadoTelaPerfil extends State<TelaPerfil> {
  late final TextEditingController _controladorTelefone;
  late final TextEditingController _controladorNomeCompleto;
  late final TextEditingController _controladorEmail;
  late final TextEditingController _controladorCpf;
  late final TextEditingController _controladorCep;
  late final TextEditingController _controladorRua;
  late final TextEditingController _controladorBairro;
  late final TextEditingController _controladorNumero;

  double _avaliacao = 4.8;
  int _totalConsultas = 3;
  final String _tipoConta = 'Paciente';

  bool _carregando = true;
  bool _editando = false;
  bool _salvando = false;
  String? _erro;

  static const double _quebraCelular = 700;

  @override
  void initState() {
    super.initState();
    _controladorTelefone = TextEditingController();
    _controladorNomeCompleto = TextEditingController();
    _controladorEmail = TextEditingController();
    _controladorCpf = TextEditingController();
    _controladorCep = TextEditingController();
    _controladorRua = TextEditingController();
    _controladorBairro = TextEditingController();
    _controladorNumero = TextEditingController();

    _carregarPerfil();
  }

  @override
  void dispose() {
    _controladorTelefone.dispose();
    _controladorNomeCompleto.dispose();
    _controladorEmail.dispose();
    _controladorCpf.dispose();
    _controladorCep.dispose();
    _controladorRua.dispose();
    _controladorBairro.dispose();
    _controladorNumero.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    if (SessaoUsuario.id == null) {
      setState(() {
        _carregando = false;
        _erro = "Sessão inválida. Faça login novamente.";
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
      _controladorNomeCompleto.text = dados['nome'] ?? '';
      _controladorEmail.text = dados['email'] ?? '';
      _controladorTelefone.text = dados['telefone'] ?? '';
      _controladorCpf.text = dados['cpf'] ?? '';
      _controladorCep.text = dados['cep'] ?? '';
      _controladorRua.text = dados['rua'] ?? '';
      _controladorBairro.text = dados['bairro'] ?? '';
      _controladorNumero.text = dados['numero'] ?? '';
      
      _avaliacao = (dados['avaliacao'] as num?)?.toDouble() ?? 5.0;
      _totalConsultas = (dados['total_consultas'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> _salvarPerfil() async {
    if (_controladorNomeCompleto.text.trim().isEmpty) {
      _mostrarErro('Nome não pode ser vazio');
      return;
    }

    setState(() => _salvando = true);

    final resultado = await ApiService.atualizarPerfil(
      SessaoUsuario.id!,
      nome: _controladorNomeCompleto.text.trim(),
      email: _controladorEmail.text.trim(),
      telefone: _controladorTelefone.text.trim(),
      cpf: _controladorCpf.text.trim(),
      cep: _controladorCep.text.trim(),
      rua: _controladorRua.text.trim(),
      bairro: _controladorBairro.text.trim(),
      numero: _controladorNumero.text.trim(),
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    if (resultado.temErro) {
      _mostrarErro(resultado.erro!);
      return;
    }

    // Update session locally
    await SessaoUsuario.salvar({
      'paciente': resultado.dados,
      'token': SessaoUsuario.token,
    });

    setState(() => _editando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _cancelarEdicao() {
    setState(() => _editando = false);
    _carregarPerfil();
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair de sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await SessaoUsuario.limpar();
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TelaLogin()),
                (route) => false,
              );
            },
            child: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      drawer: const MenuSanduiche(paginaAtiva: PaginaApp.perfil),
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
          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_erro != null)
            _construirErroWidget()
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _TituloSecao('Seu perfil:'),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_editando ? Icons.close : Icons.edit, color: AppColors.azulPrimario),
                      onPressed: _editando ? _cancelarEdicao : () => setState(() => _editando = true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PilulaInfo(
                    rotulo: 'Avaliação:',
                    valor: '${_avaliacao.toStringAsFixed(1)} ★',
                    rotuloClicavel: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PilulaInfo(
                    rotulo: 'Consultas:',
                    valor: '$_totalConsultas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _TituloSecao('Dados Pessoais:'),
            const SizedBox(height: 12),
            _CampoPerfil(
              rotulo: 'Nome Completo:',
              controlador: _controladorNomeCompleto,
              somenteLeitura: !_editando,
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              rotulo: 'Email:',
              controlador: _controladorEmail,
              somenteLeitura: !_editando,
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              rotulo: 'Telefone:',
              controlador: _controladorTelefone,
              somenteLeitura: !_editando,
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              rotulo: 'CPF:',
              controlador: _controladorCpf,
              somenteLeitura: !_editando,
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              rotulo: 'Cep:',
              controlador: _controladorCep,
              somenteLeitura: !_editando,
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              rotulo: 'Rua:',
              controlador: _controladorRua,
              somenteLeitura: true,
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              rotulo: 'Bairro:',
              controlador: _controladorBairro,
              somenteLeitura: true,
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              rotulo: 'Número:',
              controlador: _controladorNumero,
              somenteLeitura: !_editando,
            ),
            const SizedBox(height: 24),
            if (_editando) ...[
              ElevatedButton(
                onPressed: _salvando ? null : _salvarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Salvar Alterações',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _cancelarEdicao,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _construirLayoutDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BarraLateralMenu(paginaAtiva: PaginaApp.perfil),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _controladorNomeCompleto.text.isEmpty
                          ? 'Meu Perfil'
                          : _controladorNomeCompleto.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoEscuro,
                      ),
                    ),
                    Row(
                      children: [
                        if (!_carregando && _erro == null) ...[
                          OutlinedButton.icon(
                            icon: Icon(_editando ? Icons.close : Icons.edit),
                            label: Text(_editando ? 'Cancelar' : 'Editar'),
                            onPressed: _editando ? _cancelarEdicao : () => setState(() => _editando = true),
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
                  ],
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
                else ...[
                  const _TituloSecao('Sua avaliação:'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: _PilulaInfo(
                          rotulo: 'Avaliação:',
                          valor: '${_avaliacao.toStringAsFixed(1)} ★',
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 160,
                        child: _PilulaInfo(
                          rotulo: 'Consultas:',
                          valor: '$_totalConsultas',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _TituloSecao('Dados Pessoais:'),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CampoPerfil(
                              rotulo: 'Nome Completo:',
                              controlador: _controladorNomeCompleto,
                              somenteLeitura: !_editando,
                            ),
                            const SizedBox(height: 14),
                            _CampoPerfil(
                              rotulo: 'Email:',
                              controlador: _controladorEmail,
                              somenteLeitura: !_editando,
                            ),
                            const SizedBox(height: 14),
                            _CampoPerfil(
                              rotulo: 'Telefone:',
                              controlador: _controladorTelefone,
                              somenteLeitura: !_editando,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CampoPerfil(
                              rotulo: 'CPF:',
                              controlador: _controladorCpf,
                              somenteLeitura: !_editando,
                            ),
                            const SizedBox(height: 14),
                            _CampoPerfil(
                              rotulo: 'Cep:',
                              controlador: _controladorCep,
                              somenteLeitura: !_editando,
                            ),
                            const SizedBox(height: 14),
                            _CampoPerfil(
                              rotulo: 'Rua:',
                              controlador: _controladorRua,
                              somenteLeitura: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CampoPerfil(
                              rotulo: 'Bairro:',
                              controlador: _controladorBairro,
                              somenteLeitura: true,
                            ),
                            const SizedBox(height: 14),
                            _CampoPerfil(
                              rotulo: 'Número:',
                              controlador: _controladorNumero,
                              somenteLeitura: !_editando,
                            ),
                            const SizedBox(height: 14),
                            _CampoEstatico(
                              rotulo: 'Tipo de conta:',
                              valor: _tipoConta,
                              corValor: AppColors.azulPrimario,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_editando) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _cancelarEdicao,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _salvando ? null : _salvarPerfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulPrimario,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: _salvando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Salvar Alterações',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
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
          Text('Erro ao carregar dados: $_erro', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _carregarPerfil,
            child: const Text('Tentar Novamente'),
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

class _PilulaInfo extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool rotuloClicavel;

  const _PilulaInfo({
    required this.rotulo,
    required this.valor,
    this.rotuloClicavel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: rotuloClicavel ? AppColors.azulPrimario : AppColors.textoCinza,
            decoration: rotuloClicavel ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.preenchimentoCampo,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.bordaCampo),
          ),
          alignment: Alignment.center,
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textoEscuro,
            ),
          ),
        ),
      ],
    );
  }
}

class _CampoPerfil extends StatelessWidget {
  final String rotulo;
  final TextEditingController controlador;
  final bool somenteLeitura;

  const _CampoPerfil({
    required this.rotulo,
    required this.controlador,
    this.somenteLeitura = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textoCinza,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          readOnly: somenteLeitura,
          style: TextStyle(
            fontSize: 13,
            color: somenteLeitura ? AppColors.textoCinza : AppColors.textoEscuro,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: somenteLeitura ? AppColors.bordaCampo : AppColors.fundoCartao,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.bordaCampo),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.bordaCampo),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.azulPrimario),
            ),
          ),
        ),
      ],
    );
  }
}

class _CampoEstatico extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color? corValor;

  const _CampoEstatico({
    required this.rotulo,
    required this.valor,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textoCinza,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.fundoCartao,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.bordaCampo),
          ),
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: corValor ?? AppColors.textoEscuro,
            ),
          ),
        ),
      ],
    );
  }
}
