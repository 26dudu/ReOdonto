import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/recuperarSenha/cabecalho_marca.dart';
import '../widgets/recuperarSenha/campo_login.dart';
import '../utils/avisos.dart';
import '../utils/validadores.dart';
import '../widgets/botao_principal.dart';

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

  static const double _larguraMaxima = 440;
  static const double _quebraCelular = 600;

  @override
  void dispose() {
    _controladorCodigo.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  bool get _temCaractereEspecial => senhaTemCaractereEspecial(_controladorSenha.text);
  bool get _temMinimoCaracteres => senhaTemMinimoCaracteres(_controladorSenha.text);
  bool get _temMaiusculaMinusculaNumero => senhaTemMaiusculaMinusculaNumero(_controladorSenha.text);
  bool get _senhaValida => senhaAtendeRequisitos(_controladorSenha.text);

  Future<void> _reenviarCodigo() async {
    setState(() => _reenviando = true);

    final resultado =
        await ApiService.solicitarCodigoRecuperacao(email: widget.email);

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
      mostrarAviso(context, 'A senha ainda não atende todos os requisitos', erro: true);
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

    mostrarAviso(context, 'Senha redefinida com sucesso! Faça login com a nova senha.', sucesso: true);

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricoes) {
            final celular = restricoes.maxWidth < _quebraCelular;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: celular ? 32.0 : 48.0,
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _larguraMaxima),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      const CabecalhoMarca(),

                      const SizedBox(height: 40),
                      const Text(
                        'Insira sua nova senha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C2434),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enviamos um código para\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textoCinza,
                        ),
                      ),
                      const SizedBox(height: 28),

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
                                icon: const Icon(Icons.refresh,
                                    color: Color(0xFF58606A)),
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black45,
                          ),
                          onPressed: _carregando
                              ? null
                              : () =>
                                  setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Obrigatório:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E5FD8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RequisitoSenha(
                        atendido: _temCaractereEspecial,
                        texto: 'Um caractere especial',
                      ),
                      const SizedBox(height: 4),
                      _RequisitoSenha(
                        atendido: _temMinimoCaracteres,
                        texto: 'Mínimo de 8 caracteres',
                      ),
                      const SizedBox(height: 4),
                      _RequisitoSenha(
                        atendido: _temMaiusculaMinusculaNumero,
                        texto: 'Letras maiúsculas, minúsculas e um número',
                      ),

                      const SizedBox(height: 28),
                      BotaoPrincipal(
                        texto: 'Confirmar',
                        carregando: _carregando,
                        cor: const Color(0xFF1E5FD8),
                        onPressed: _carregando ? null : _confirmar,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


//Uma linha da checklist de requisitos da senha
class _RequisitoSenha extends StatelessWidget {
  final bool atendido;
  final String texto;

  const _RequisitoSenha({required this.atendido, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          atendido ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: atendido ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            color: atendido ? AppColors.textoEscuro : AppColors.textoCinza,
          ),
        ),
      ],
    );
  }
}