import 'package:flutter/material.dart';
import '../models/dados_cadastro.dart';
import '../services/api_service.dart';
import '../utils/avisos.dart';
import '../utils/validadores.dart';
import '../widgets/botao_principal.dart';
import '../widgets/botao_visibilidade_senha.dart';
import '../widgets/cadastro/cabecalhoCadastro.dart';
import '../widgets/cadastro/campo_cadastro.dart';
import '../widgets/cadastro/pagina_cadastro.dart';
import 'telaVerificarEmail.dart';

// MUDANÇAS NESTE ARQUIVO (de 245 para 151 linhas):
//  • os 5 campos recebidos (nome, email, ...) viraram UM só: `dados` (model DadosCadastro).
//  • o Scaffold/cartão/Form/botão voltar viraram o widget PaginaCadastro.
//  • o _IndicadorEtapa (duplicado) virou o widget IndicadorEtapa.
//  • os dois "olhinhos" de senha viraram o widget BotaoVisibilidadeSenha.

class TelaSenhaCadastro extends StatefulWidget {
  // Dados da tela anterior (nome, e-mail, telefone, CPF/CNPJ e CRO).
  final DadosCadastro dados;

  // Construtor que exige que os dados sejam enviados quando a tela for aberta.
  const TelaSenhaCadastro({super.key, required this.dados});

  @override
  State<TelaSenhaCadastro> createState() => _TelaSenhaCadastroState();
}

class _TelaSenhaCadastroState extends State<TelaSenhaCadastro> {
  final _controladorSenha = TextEditingController();
  final _controladorConfirmar = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _ocultarSenha = true;
  bool _ocultarConfirmar = true;
  bool _carregando = false;

  @override
  void dispose() {
    _controladorSenha.dispose();
    _controladorConfirmar.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_carregando) return;

    setState(() => _carregando = true);

    // Espera o ApiService tentar cadastrar o usuário com os dados.
    final resultado = await ApiService.cadastrar(
      nome: widget.dados.nome,
      email: widget.dados.email,
      senha: _controladorSenha.text,
      telefone: widget.dados.telefone,
      cpfCnpj: widget.dados.cpfCnpj,
      cro: widget.dados.cro,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado.temErro) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }

    mostrarAviso(
      context,
      'Enviamos um código para o seu email. Digite-o para concluir o cadastro.',
      sucesso: true,
    );
    // A conta ainda não existe: só é criada quando o código for confirmado.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => TelaVerificarEmail(email: widget.dados.email),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PaginaCadastro(
      formKey: _formKey,
      // Índice 1 = segunda etapa ativa.
      etapaAtual: 1,
      children: [
        const SignupHeader(
          titulo: 'Crie sua senha',
          subtitulo: 'Quase lá! Defina uma senha segura.',
          mostrarLogo: false,
        ),
        const SizedBox(height: 28),

        // Senha
        CampoCadastro(
          rotulo: 'Senha',
          hint: 'Mínimo 8 caracteres',
          icone: Icons.lock_outline,
          controller: _controladorSenha,
          obscureText: _ocultarSenha,
          enabled: !_carregando,
          validator: validarSenhaCadastro,
          sufixo: BotaoVisibilidadeSenha(
            oculta: _ocultarSenha,
            cor: Colors.black45,
            onPressed: _carregando
                ? null
                : () => setState(() => _ocultarSenha = !_ocultarSenha),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Use pelo menos 8 caracteres, com letras e números.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Confirmar senha
        CampoCadastro(
          rotulo: 'Confirme sua senha',
          hint: 'Repita a senha',
          icone: Icons.lock_outline,
          controller: _controladorConfirmar,
          obscureText: _ocultarConfirmar,
          enabled: !_carregando,
          validator: (confirmarSenha) {
            if (confirmarSenha == null || confirmarSenha.isEmpty) {
              return 'Confirme sua senha';
            }
            if (confirmarSenha != _controladorSenha.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
          sufixo: BotaoVisibilidadeSenha(
            oculta: _ocultarConfirmar,
            cor: Colors.black45,
            onPressed: _carregando
                ? null
                : () => setState(() => _ocultarConfirmar = !_ocultarConfirmar),
          ),
        ),
        const SizedBox(height: 32),

        BotaoPrincipal(
          texto: 'Criar conta',
          carregando: _carregando,
          onPressed: _carregando ? null : _criarConta,
        ),
      ],
    );
  }
}
