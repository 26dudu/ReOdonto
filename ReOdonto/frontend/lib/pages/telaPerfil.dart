import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_navegacao.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _EstadoTelaPerfil();
}

class _EstadoTelaPerfil extends State<TelaPerfil> {
  // TODO: esses campos ainda não existem em SessaoUsuario/ApiService.
  // Por enquanto são inicializados com o que já temos (nome/email) e
  // valores vazios para o resto — quando o backend expuser esses dados
  // (GET /pacientes/me, por exemplo), é só preencher os controllers aqui.
  late final _controladorTelefone = TextEditingController();
  late final _controladorNomeCompleto = TextEditingController(
    text: SessaoUsuario.nome ?? '',
  );
  late final _controladorEmail = TextEditingController(
    text: SessaoUsuario.email ?? '',
  );
  final _controladorCpf = TextEditingController();
  final _controladorCep = TextEditingController();
  final _controladorRua = TextEditingController();
  final _controladorBairro = TextEditingController();
  final _controladorNumero = TextEditingController();

  // Avaliação e total de consultas dependem do backend, que ainda não
  // expõe esses dados — começam em 0 e devem ser populados quando o
  // endpoint (ex.: GET /pacientes/me) retornar os valores reais.
  final double _avaliacao = 0.0;
  final int _totalConsultas = 0;
  final String _tipoConta = 'Paciente';

  static const double _quebraCelular = 700;

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
          const _TituloSecao('Sua avaliação:'),
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
            rotulo: 'Telefone:',
            controlador: _controladorTelefone,
            somenteLeitura: true,
          ),
          const SizedBox(height: 14),
          _CampoPerfil(
            rotulo: 'Nome Completo:',
            controlador: _controladorNomeCompleto,
            somenteLeitura: true,
          ),
          const SizedBox(height: 14),
          _CampoPerfil(
            rotulo: 'Email:',
            controlador: _controladorEmail,
            somenteLeitura: true,
          ),
          const SizedBox(height: 14),
          _CampoPerfil(
            rotulo: 'CPF:',
            controlador: _controladorCpf,
            somenteLeitura: true,
          ),
          const SizedBox(height: 14),
          _CampoPerfil(
            rotulo: 'Cep:',
            controlador: _controladorCep,
            somenteLeitura: true,
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
            somenteLeitura: true,
          ),
          const SizedBox(height: 24),
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
                const SizedBox(height: 28),
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
                            rotulo: 'Telefone:',
                            controlador: _controladorTelefone,
                            somenteLeitura: true,
                          ),
                          const SizedBox(height: 14),
                          _CampoPerfil(
                            rotulo: 'Nome Completo:',
                            controlador: _controladorNomeCompleto,
                            somenteLeitura: true,
                          ),
                          const SizedBox(height: 14),
                          _CampoPerfil(
                            rotulo: 'Email:',
                            controlador: _controladorEmail,
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
                            rotulo: 'CPF:',
                            controlador: _controladorCpf,
                            somenteLeitura: true,
                          ),
                          const SizedBox(height: 14),
                          _CampoPerfil(
                            rotulo: 'Cep:',
                            controlador: _controladorCep,
                            somenteLeitura: true,
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
                            somenteLeitura: true,
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
              ],
            ),
          ),
        ),
      ],
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

/// Pílula com rótulo (opcionalmente sublinhado/clicável) e valor em destaque.
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
            color: rotuloClicavel
                ? AppColors.azulPrimario
                : AppColors.textoCinza,
            decoration: rotuloClicavel
                ? TextDecoration.underline
                : TextDecoration.none,
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

/// Campo de exibição/edição de dado pessoal (rótulo em cima + caixa embaixo),
/// sem ícone, igual ao estilo do mockup de Perfil.
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
            color: somenteLeitura
                ? AppColors.textoCinza
                : AppColors.textoEscuro,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: somenteLeitura
                ? AppColors.bordaCampo
                : AppColors.fundoCartao,
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




/// Igual ao _CampoPerfil, mas para um valor fixo (ex.: Tipo de conta),
/// sem TextField editável.
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
