import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dados_cadastro.dart';
import '../utils/mascaras.dart';
import '../utils/validadores.dart';
import '../widgets/cadastro/cabecalhoCadastro.dart';
import '../widgets/cadastro/campo_cadastro.dart';
import '../widgets/cadastro/pagina_cadastro.dart';
import 'telaSenhaCadastro.dart';
import '../widgets/botao_principal.dart';

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

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorTelefone.dispose();
    _controladorCpfCnpj.dispose();
    _controladorCro.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;

    final dados = DadosCadastro(
      nome: _controladorNome.text.trim(),
      email: _controladorEmail.text.trim(),
      telefone: _controladorTelefone.text.trim(),
      cpfCnpj: _controladorCpfCnpj.text.trim(),
      cro: _controladorCro.text.trim(),
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TelaSenhaCadastro(dados: dados)));
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCadastro(
      formKey: _formKey,
      etapaAtual: 0,
      espacoAposVoltar: 4,
      espacoAposIndicador: 16,
      children: [
        const SignupHeader(
          titulo: 'Crie sua conta de dentista',
          subtitulo: 'Preencha seus dados para começar.',
        ),
        const SizedBox(height: 24),

        CampoCadastro(
          rotulo: 'Nome completo',
          hint: 'Ex: Dr. João Silva',
          icone: Icons.person_outline,
          controller: _controladorNome,
          validator: validarNome,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^\s+'))],
        ),
        const SizedBox(height: 16),

        CampoCadastro(
          rotulo: 'Email',
          hint: 'seu@email.com',
          icone: Icons.email_outlined,
          controller: _controladorEmail,
          validator: validarEmail,
          tipo: TextInputType.emailAddress,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        ),
        const SizedBox(height: 16),

        CampoCadastro(
          rotulo: 'Telefone',
          hint: '(11) 99999-9999',
          icone: Icons.phone_outlined,
          controller: _controladorTelefone,
          validator: validarTelefone,
          tipo: TextInputType.phone,
          inputFormatters: [TelefoneInputFormatter()],
        ),
        const SizedBox(height: 16),

        CampoCadastro(
          rotulo: 'CPF ou CNPJ',
          hint: 'Digite CPF (000.000.000-00) ou CNPJ',
          icone: Icons.badge_outlined,
          controller: _controladorCpfCnpj,
          validator: validarCpfCnpj,
          tipo: TextInputType.number,
          inputFormatters: [CpfCnpjInputFormatter()],
        ),
        const SizedBox(height: 4),
        const Text(
          'O formato é detectado automaticamente ao digitar.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        CampoCadastro(
          rotulo: 'CRO (opcional)',
          hint: 'Ex: SP-12345',
          icone: Icons.workspace_premium_outlined,
          controller: _controladorCro,
          inputFormatters: [CroInputFormatter()],
        ),
        const SizedBox(height: 28),

        BotaoPrincipal(texto: 'Continuar', onPressed: _continuar),
      ],
    );
  }
}
