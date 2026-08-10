import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../theme/app_colors.dart';
import '../widgets/cadastro/cabecalho.dart';
import '../widgets/cadastro/infoBasicas.dart';
import '../widgets/cadastro/enderecoInfo.dart';
import '../widgets/cadastro/senhas.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _EstadoSignupPage();
}

class _EstadoSignupPage extends State<SignupPage> {
  final _controladorTelefone = TextEditingController();
  final _controladorNomeCompleto = TextEditingController();
  final _controladorEmail = TextEditingController();

  final _controladorCpf = TextEditingController();
  final _controladorCep = TextEditingController();
  final _controladorRua = TextEditingController();
  final _controladorBairro = TextEditingController();
  final _controladorNumero = TextEditingController();

  final _controladorSenha = TextEditingController();
  final _controladorConfirmarSenha = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfirmarSenha = true;

  final _controladorPaginaCelular = PageController();
  int _etapaAtual = 0;
  bool _carregando = false;

  static const double _quebraCelular = 700;
  static const double _larguraMaximaCardDesktop = 780;
  static const double _larguraMaximaCardCelular = 440;

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
    _controladorSenha.dispose();
    _controladorConfirmarSenha.dispose();
    _controladorPaginaCelular.dispose();
    super.dispose();
  }

  void _irParaEtapaSenha() {
    setState(() => _etapaAtual = 1);
    _controladorPaginaCelular.animateToPage(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _irParaEtapaDadosPessoais() {
    setState(() => _etapaAtual = 0);
    _controladorPaginaCelular.animateToPage(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _criarConta() async {
    setState(() => _carregando = true);

    // TODO: integrar com o serviço/autenticação real
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _carregando = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Conta criada (exemplo).')));
  }

  void _cadastroGoogle() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cadastro com Google.')));
  }

  @override
  Widget build(BuildContext contexto) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (contexto, restricoes) {
            final Celular = restricoes.maxWidth < _quebraCelular;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Celular ? 20 : 24,
                vertical: 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Celular
                        ? _larguraMaximaCardCelular
                        : _larguraMaximaCardDesktop, 
                  ),
                  child: Celular
                      ? _construirCardCelular()
                      : _construirCardDesktop(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _construirCardDesktop() {
    return _Card(
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
  children: [
    IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(
        Icons.arrow_back,
        color: AppColors.textoEscuro,
      ),
    ),
  ],
),
          const SignupHeader(
            titulo: 'Crie a sua conta no ReOdonto!',
            subtitulo: 'E facilite sua vida!',
            logoNoTopo: true,
          ),
          const SizedBox(height: 28),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BasicInfoFields(
                        controladorTelefone: _controladorTelefone,
                        controladorNomeCompleto: _controladorNomeCompleto,
                        controladorEmail: _controladorEmail,
                      ),
                      const SizedBox(height: 16),
                      SecurityInfoFields(
                        controladorSenha: _controladorSenha,
                        controladorConfirmarSenha: _controladorConfirmarSenha,
                        ocultarSenha: _ocultarSenha,
                        ocultarConfirmarSenha: _ocultarConfirmarSenha,
                        aoAlternarOcultarSenha: () =>
                            setState(() => _ocultarSenha = !_ocultarSenha),
                        aoAlternarOcultarConfirmarSenha: () => setState(
                          () =>
                              _ocultarConfirmarSenha = !_ocultarConfirmarSenha,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: AddressInfoFields(
                    controladorCpf: _controladorCpf,
                    controladorCep: _controladorCep,
                    controladorRua: _controladorRua,
                    controladorBairro: _controladorBairro,
                    controladorNumero: _controladorNumero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _carregando ? null : _criarConta,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulPrimario,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _carregando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Criar conta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('ou', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
            ],
          ),
          const SizedBox(height: 18),
          SignInButton(
            Buttons.google,
            text: 'Cadastrar com Google',
            onPressed: _cadastroGoogle,
          ),
        ],
      ),
    );
  }

  Widget _construirCardCelular() {
    return _Card(
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IndicadorEtapa(etapaAtual: _etapaAtual, totalEtapas: 2),
          const SizedBox(height: 16),
          SizedBox(
            height: 560,
            child: PageView(
              controller: _controladorPaginaCelular,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (indice) => setState(() => _etapaAtual = indice),
              children: [
                _construirEtapaDadosPessoaisCelular(),
                _construirEtapaSenhaCelular(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEtapaDadosPessoaisCelular() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Row(
  children: [
    IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(
        Icons.arrow_back,
        color: AppColors.textoEscuro,
      ),
    ),
  ],
),
          const SignupHeader(
            titulo: 'Crie a sua conta no ReOdonto!',
            subtitulo: 'E facilite sua vida!',
          ),
          const SizedBox(height: 20),
          BasicInfoFields(
            controladorTelefone: _controladorTelefone,
            controladorNomeCompleto: _controladorNomeCompleto,
            controladorEmail: _controladorEmail,
          ),
          const SizedBox(height: 16),
          AddressInfoFields(
            controladorCpf: _controladorCpf,
            controladorCep: _controladorCep,
            controladorRua: _controladorRua,
            controladorBairro: _controladorBairro,
            controladorNumero: _controladorNumero,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _irParaEtapaSenha,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulPrimario,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('ou', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
            ],
          ),
          const SizedBox(height: 18),
          SignInButton(
            Buttons.google,
            text: 'Cadastrar com Google',
            onPressed: _cadastroGoogle,
          ),
        ],
      ),
    );
  }

  Widget _construirEtapaSenhaCelular() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _irParaEtapaDadosPessoais,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textoEscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SignupHeader(
            titulo: 'Continue criando sua conta',
            mostrarLogo: false,
          ),
          const SizedBox(height: 20),
          SecurityInfoFields(
            controladorSenha: _controladorSenha,
            controladorConfirmarSenha: _controladorConfirmarSenha,
            ocultarSenha: _ocultarSenha,
            ocultarConfirmarSenha: _ocultarConfirmarSenha,
            aoAlternarOcultarSenha: () =>
                setState(() => _ocultarSenha = !_ocultarSenha),
            aoAlternarOcultarConfirmarSenha: () => setState(
              () => _ocultarConfirmarSenha = !_ocultarConfirmarSenha,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _carregando ? null : _criarConta,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulPrimario,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _carregando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Criar conta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('ou', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
            ],
          ),
          const SizedBox(height: 18),
          SignInButton(
            Buttons.google,
            text: 'Cadastrar com Google',
            onPressed: _cadastroGoogle,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget conteudo;

  const _Card({required this.conteudo});

  @override
  Widget build(BuildContext contexto) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.fundoCartao,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: conteudo,
    );
  }
}

class _IndicadorEtapa extends StatelessWidget {
  final int etapaAtual;
  final int totalEtapas;

  const _IndicadorEtapa({required this.etapaAtual, required this.totalEtapas});

  @override
  Widget build(BuildContext contexto) {
    return Row(
      children: List.generate(totalEtapas, (indice) {
        final estaAtiva = indice == etapaAtual;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: estaAtiva ? 22 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: estaAtiva ? AppColors.azulPrimario : AppColors.bordaCampo,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
