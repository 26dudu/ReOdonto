// Material Design.
import 'package:flutter/material.dart';
// Fornece FilteringTextInputFormatter (filtros de digitação).
import 'package:flutter/services.dart';
// Model com os dados desta etapa (nome, e-mail, telefone, CPF/CNPJ, CRO).
import '../models/dados_cadastro.dart';
// Máscaras de CPF/CNPJ, telefone e CRO.
import '../utils/mascaras.dart';
// Validators de nome, e-mail, telefone e CPF/CNPJ (MOVIDOS para cá do antigo corpo desta tela).
import '../utils/validadores.dart';
// Cabeçalho do cadastro (SignupHeader).
import '../widgets/cadastro/cabecalhoCadastro.dart';
// Campo de formulário do cadastro (CampoCadastro).
import '../widgets/cadastro/campo_cadastro.dart';
// Casca do cadastro (cartão + Form + botão voltar + indicador de etapa).
import '../widgets/cadastro/pagina_cadastro.dart';
// Próxima etapa do cadastro (criar senha).
import 'telaSenhaCadastro.dart';
// Botão principal.
import '../widgets/botao_principal.dart';

// MUDANÇAS NESTE ARQUIVO (de 386 para 173 linhas):
//  • import do sign_in_button REMOVIDO (não era usado aqui).
//  • validators de nome/e-mail/telefone/CPF/CNPJ foram para utils/validadores.dart.
//  • o Scaffold/cartão/Form/botão voltar viraram o widget PaginaCadastro.
//  • o _IndicadorEtapa virou o widget IndicadorEtapa (era duplicado na tela de senha).
//  • os 5 textos enviados à próxima tela agora viajam no model DadosCadastro.

// TELA 1 DO CADASTRO DE DENTISTA: dados pessoais (nome, e-mail, telefone, CPF/CNPJ, CRO).
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _EstadoSignupPage();
}

class _EstadoSignupPage extends State<SignupPage> {
  // Chave global que conecta e controla todos os campos do formulário.
  // É usada para acionar a validação de todos os campos de uma só vez
  // e fazer aparecer as mensagens de erro em vermelho abaixo deles.
  final _formKey = GlobalKey<FormState>();

  // Um controller para cada campo, para ler o que foi digitado.
  final _controladorNome = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorTelefone = TextEditingController();
  final _controladorCpfCnpj = TextEditingController();
  final _controladorCro = TextEditingController();

  @override
  // Libera todos os controllers ao fechar a tela.
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorTelefone.dispose();
    _controladorCpfCnpj.dispose();
    _controladorCro.dispose();
    super.dispose();
  }

  // Botão "Continuar": valida e avança para a tela de senha.
  void _continuar() {
    // Se algum campo estiver inválido, mostra os erros e não avança.
    if (!_formKey.currentState!.validate()) return;

    // Junta o que foi digitado (trim() tira espaços sobrando) num único objeto.
    final dados = DadosCadastro(
      nome: _controladorNome.text.trim(),
      email: _controladorEmail.text.trim(),
      telefone: _controladorTelefone.text.trim(),
      cpfCnpj: _controladorCpfCnpj.text.trim(),
      cro: _controladorCro.text.trim(),
    );

    // Empilha a próxima tela passando os dados digitados.
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TelaSenhaCadastro(dados: dados)));
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCadastro(
      formKey: _formKey,
      // Índice 0 = primeira etapa ativa.
      etapaAtual: 0,
      // Nesta tela o espaçamento é um pouco menor que na tela de senha.
      espacoAposVoltar: 4,
      espacoAposIndicador: 16,
      children: [
        // Título + subtítulo (com logo, pois mostrarLogo não foi desativado).
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
          validator: validarNome,
          // Impede começar o texto com espaços (^\s+ = espaços no início).
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^\s+'))],
        ),
        const SizedBox(height: 16),

        // Email
        CampoCadastro(
          rotulo: 'Email',
          hint: 'seu@email.com',
          icone: Icons.email_outlined,
          controller: _controladorEmail,
          validator: validarEmail,
          // Teclado de e-mail no celular.
          tipo: TextInputType.emailAddress,
          // Bloqueia qualquer espaço (\s) no e-mail.
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        ),
        const SizedBox(height: 16),

        // Telefone com máscara
        CampoCadastro(
          rotulo: 'Telefone',
          hint: '(11) 99999-9999',
          icone: Icons.phone_outlined,
          controller: _controladorTelefone,
          validator: validarTelefone,
          // Teclado numérico de telefone.
          tipo: TextInputType.phone,
          // Aplica a máscara (00) 00000-0000.
          inputFormatters: [TelefoneInputFormatter()],
        ),
        const SizedBox(height: 16),

        // CPF / CNPJ com máscara automática
        CampoCadastro(
          rotulo: 'CPF ou CNPJ',
          hint: 'Digite CPF (000.000.000-00) ou CNPJ',
          icone: Icons.badge_outlined,
          controller: _controladorCpfCnpj,
          validator: validarCpfCnpj,
          // Teclado numérico.
          tipo: TextInputType.number,
          // Máscara que alterna sozinha entre CPF e CNPJ.
          inputFormatters: [CpfCnpjInputFormatter()],
        ),
        const SizedBox(height: 4),
        // Observação pequena sob o campo.
        const Text(
          'O formato é detectado automaticamente ao digitar.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // CRO (opcional) — sem validator, pois o campo é opcional.
        CampoCadastro(
          rotulo: 'CRO (opcional)',
          hint: 'Ex: SP-12345',
          icone: Icons.workspace_premium_outlined,
          controller: _controladorCro,
          inputFormatters: [CroInputFormatter()],
        ),
        const SizedBox(height: 28),

        // Botão Continuar
        BotaoPrincipal(texto: 'Continuar', onPressed: _continuar),
      ],
    );
  }
}
