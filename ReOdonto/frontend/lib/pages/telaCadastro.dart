import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../theme/app_colors.dart';
import '../utils/mascaras.dart';
import '../widgets/cadastro/cabecalhoCadastro.dart';
import '../widgets/cadastro/campo_cadastro.dart';
import 'telaSenhaCadastro.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _EstadoSignupPage();
}

class _EstadoSignupPage extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _controladorNome = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorTelefone = TextEditingController();
  final _controladorCpfCnpj = TextEditingController();
  final _controladorCro = TextEditingController();

  static const double _larguraMaxima = 480;

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorTelefone.dispose();
    _controladorCpfCnpj.dispose();
    _controladorCro.dispose();
    super.dispose();
  }

  String? _validarNome(String? v) {
    if (v == null || v.trim().isEmpty) return 'Preencha o nome completo';
    if (v.trim().length < 3) return 'Nome deve ter pelo menos 3 caracteres';
    return null;
  }

  String? _validarEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Preencha o email';
    final regex = RegExp(
      r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$',
      caseSensitive: false,
    );
    if (!regex.hasMatch(v.trim())) return 'Email inválido';
    return null;
  }

  String? _validarTelefone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Preencha o telefone';
    final digitos = v.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 10 || digitos.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  String? _validarCpfCnpj(String? v) {
    if (v == null || v.trim().isEmpty) return 'Preencha o CPF ou CNPJ';
    final digitos = v.replaceAll(RegExp(r'\D'), '');
    if (digitos.length == 11) {
      if (!_validarCpf(digitos)) return 'CPF inválido';
    } else if (digitos.length == 14) {
      if (!_validarCnpj(digitos)) return 'CNPJ inválido';
    } else {
      return 'Digite um CPF (11 dígitos) ou CNPJ (14 dígitos)';
    }
    return null;
  }

  bool _validarCpf(String cpf) {
    if (cpf.length != 11 || cpf == cpf[0] * 11) return false;
    for (int pos = 9; pos <= 10; pos++) {
      int soma = 0;
      for (int i = 0; i < pos; i++) {
        soma += int.parse(cpf[i]) * (pos + 1 - i);
      }
      final digito = (soma * 10 % 11) % 10;
      if (digito != int.parse(cpf[pos])) return false;
    }
    return true;
  }

  bool _validarCnpj(String cnpj) {
    if (cnpj.length != 14 || cnpj == cnpj[0] * 14) return false;
    final p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    final p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (final entry in [(p1, 12), (p2, 13)]) {
      final pesos = entry.$1;
      final pos = entry.$2;
      int soma = 0;
      for (int i = 0; i < pos; i++) {
        soma += int.parse(cnpj[i]) * pesos[i];
      }
      final resto = soma % 11;
      final digito = resto < 2 ? 0 : 11 - resto;
      if (digito != int.parse(cnpj[pos])) return false;
    }
    return true;
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaSenhaCadastro(
          nome: _controladorNome.text.trim(),
          email: _controladorEmail.text.trim(),
          telefone: _controladorTelefone.text.trim(),
          cpfCnpj: _controladorCpfCnpj.text.trim(),
          cro: _controladorCro.text.trim(),
        ),
      ),
    );
  }

  void _tratarCadastroGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro com Google em breve.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _larguraMaxima),
              child: Container(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Botão voltar
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.textoEscuro,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Indicador de etapa
                      _IndicadorEtapa(etapaAtual: 0),
                      const SizedBox(height: 16),

                      const SignupHeader(
                        titulo: 'Crie sua conta de dentista',
                        subtitulo: 'Preencha seus dados para começar.',
                      ),
                      const SizedBox(height: 24),

                      // Nome
                      CampoCadastro(
                        rotulo: 'Nome completo',
                        hint: 'Ex: Dr. João Silva',
                        icone: Icons.person_outline,
                        controller: _controladorNome,
                        validator: _validarNome,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'^\s+')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email
                      CampoCadastro(
                        rotulo: 'Email',
                        hint: 'seu@email.com',
                        icone: Icons.email_outlined,
                        controller: _controladorEmail,
                        validator: _validarEmail,
                        tipo: TextInputType.emailAddress,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Telefone com máscara
                      CampoCadastro(
                        rotulo: 'Telefone',
                        hint: '(11) 99999-9999',
                        icone: Icons.phone_outlined,
                        controller: _controladorTelefone,
                        validator: _validarTelefone,
                        tipo: TextInputType.phone,
                        inputFormatters: [TelefoneInputFormatter()],
                      ),
                      const SizedBox(height: 16),

                      // CPF / CNPJ com máscara automática
                      CampoCadastro(
                        rotulo: 'CPF ou CNPJ',
                        hint: 'Digite CPF (000.000.000-00) ou CNPJ',
                        icone: Icons.badge_outlined,
                        controller: _controladorCpfCnpj,
                        validator: _validarCpfCnpj,
                        tipo: TextInputType.number,
                        inputFormatters: [CpfCnpjInputFormatter()],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'O formato é detectado automaticamente ao digitar.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // CRO (opcional)
                      CampoCadastro(
                        rotulo: 'CRO (opcional)',
                        hint: 'Ex: SP-12345',
                        icone: Icons.workspace_premium_outlined,
                        controller: _controladorCro,
                        inputFormatters: [CroInputFormatter()],
                      ),
                      const SizedBox(height: 28),

                      // Botão Continuar
                      ElevatedButton(
                        onPressed: _continuar,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const _Divisor(),
                      const SizedBox(height: 18),

                      SignInButton(
                        Buttons.google,
                        text: 'Cadastrar com Google',
                        onPressed: _tratarCadastroGoogle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicadorEtapa extends StatelessWidget {
  final int etapaAtual;
  const _IndicadorEtapa({required this.etapaAtual});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final ativa = i == etapaAtual;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: ativa ? 22 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: ativa ? AppColors.azulPrimario : const Color(0xFFCBD5E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('ou', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
      ],
    );
  }
}
