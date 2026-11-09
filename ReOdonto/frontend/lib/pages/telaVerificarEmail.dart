import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/avisos.dart';
import '../widgets/botao_principal.dart';
import '../widgets/recuperarSenha/campo_login.dart';
import '../widgets/recuperarSenha/pagina_autenticacao.dart';

class TelaVerificarEmail extends StatefulWidget {
  final String email;

  const TelaVerificarEmail({super.key, required this.email});

  @override
  State<TelaVerificarEmail> createState() => _TelaVerificarEmailState();
}

class _TelaVerificarEmailState extends State<TelaVerificarEmail> {
  static const _azul = Color(0xFF1E5FD8);
  static const _verde = Color(0xFF00C1A2);
  static const _tamanhoCodigo = 6;

  final _controladorCodigo = TextEditingController();
  bool _carregando = false;
  bool _reenviando = false;

  @override
  void dispose() {
    _controladorCodigo.dispose();
    super.dispose();
  }

  Future<void> _reenviarCodigo() async {
    setState(() => _reenviando = true);

    final resultado = await ApiService.reenviarVerificacaoEmail(
      email: widget.email,
    );

    if (!mounted) return;
    setState(() => _reenviando = false);

    if (resultado.temErro) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }

    mostrarAviso(context, 'Enviamos um novo código para o seu email.');
  }

  Future<void> _confirmar() async {
    final codigo = _controladorCodigo.text.trim();

    if (codigo.length != _tamanhoCodigo) {
      mostrarAviso(
        context,
        'Digite o código de $_tamanhoCodigo dígitos recebido por email',
        erro: true,
      );
      return;
    }

    setState(() => _carregando = true);

    final resultado = await ApiService.verificarEmail(
      email: widget.email,
      codigo: codigo,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado.temErro) {
      mostrarAviso(context, resultado.erro!, erro: true);
      return;
    }

    mostrarAviso(
      context,
      'Email confirmado e conta criada! Faça login para entrar.',
      sucesso: true,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _carregando || _reenviando;

    return PaginaAutenticacao(
      children: [
        TituloAutenticacao(
          titulo: 'Confirme seu email para criar a conta',
          subtitulo: 'Enviamos um código de $_tamanhoCodigo dígitos para\n${widget.email}',
        ),
        CampoLogin(
          controller: _controladorCodigo,
          hintText: 'Código',
          enabled: !ocupado,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.mark_email_read_outlined),
          formatadores: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_tamanhoCodigo),
          ],
        ),
        const SizedBox(height: 24),
        BotaoPrincipal(
          texto: 'Confirmar',
          carregando: _carregando,
          cor: _azul,
          onPressed: ocupado ? null : _confirmar,
        ),
        const SizedBox(height: 20),
        Center(
          child: _reenviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : GestureDetector(
                  onTap: ocupado ? null : _reenviarCodigo,
                  child: const Text(
                    'Reenviar código',
                    style: TextStyle(
                      color: _verde,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: ocupado ? null : () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text(
              'Voltar para tela login',
              style: TextStyle(
                color: _verde,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
