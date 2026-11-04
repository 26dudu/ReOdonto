import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/avisos.dart';
import '../utils/validadores.dart';
import '../widgets/botao_principal.dart';
import '../widgets/botao_visibilidade_senha.dart';
import '../widgets/recuperarSenha/campo_login.dart';
import '../widgets/recuperarSenha/pagina_autenticacao.dart';
import '../widgets/recuperarSenha/requisito_senha.dart';

// MUDANÇAS NESTE ARQUIVO (de 251 para 155 linhas):
//  • o Scaffold/LayoutBuilder/rolagem/coluna/CabecalhoMarca viraram o widget PaginaAutenticacao.
//  • título + texto explicativo viraram o widget TituloAutenticacao.
//  • a lista "Obrigatório: ..." (e a classe _RequisitoSenha) viraram ChecklistRequisitosSenha.
//  • os 3 getters (_temCaractereEspecial etc.) sumiram: o checklist calcula sozinho.
//  • o "olhinho" da senha virou o widget BotaoVisibilidadeSenha.

class TelaNovaSenha extends StatefulWidget {
  final String email;

  const TelaNovaSenha({super.key, required this.email});

  @override
  State<TelaNovaSenha> createState() => _TelaNovaSenhaState();
}

class _TelaNovaSenhaState extends State<TelaNovaSenha> {
  final _controladorCodigo = TextEditingController();
  final _controladorSenha = TextEditingController();

  bool _ocultarSenha = true;
  bool _carregando = false;
  bool _reenviando = false;

  @override
  void dispose() {
    _controladorCodigo.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  // true quando a senha digitada cumpre os 3 requisitos.
  bool get _senhaValida => senhaAtendeRequisitos(_controladorSenha.text);

  Future<void> _reenviarCodigo() async {
    setState(() => _reenviando = true);

    final resultado = await ApiService.solicitarCodigoRecuperacao(
      email: widget.email,
    );

    if (!mounted) return;
    setState(() => _reenviando = false);

    if (resultado.temErro) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }

    mostrarAviso(context, 'Código reenviado para o seu email.');
  }

  Future<void> _confirmar() async {
    final codigo = _controladorCodigo.text.trim();

    if (codigo.isEmpty) {
      mostrarAviso(context, 'Digite o código recebido por email', erro: true);
      return;
    }
    if (!_senhaValida) {
      mostrarAviso(
        context,
        'A senha ainda não atende todos os requisitos',
        erro: true,
      );
      return;
    }

    setState(() => _carregando = true);

    final resultado = await ApiService.redefinirSenha(
      email: widget.email,
      codigo: codigo,
      novaSenha: _controladorSenha.text,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado.temErro) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }

    mostrarAviso(
      context,
      'Senha redefinida com sucesso! Faça login com a nova senha.',
      sucesso: true,
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PaginaAutenticacao(
      children: [
        TituloAutenticacao(
          titulo: 'Insira sua nova senha',
          subtitulo: 'Enviamos um código para\n${widget.email}',
        ),

        CampoLogin(
          controller: _controladorCodigo,
          hintText: 'Código',
          enabled: !_carregando,
          suffixIcon: _reenviando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF58606A)),
                  tooltip: 'Reenviar código',
                  onPressed: _carregando ? null : _reenviarCodigo,
                ),
        ),
        const SizedBox(height: 16),

        CampoLogin(
          controller: _controladorSenha,
          hintText: 'Nova Senha',
          enabled: !_carregando,
          obscureText: _ocultarSenha,
          suffixIcon: BotaoVisibilidadeSenha(
            oculta: _ocultarSenha,
            cor: Colors.black45,
            onPressed: _carregando
                ? null
                : () => setState(() => _ocultarSenha = !_ocultarSenha),
          ),
          // Redesenha a tela a cada letra para atualizar o checklist abaixo.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),

        // Lista "Obrigatório:" com os requisitos da senha (verde/vermelho).
        ChecklistRequisitosSenha(senha: _controladorSenha.text),

        const SizedBox(height: 28),
        BotaoPrincipal(
          texto: 'Confirmar',
          carregando: _carregando,
          cor: const Color(0xFF1E5FD8),
          onPressed: _carregando ? null : _confirmar,
        ),
      ],
    );
  }
}
