import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/cadastro/cabecalhoCadastro.dart';
import '../widgets/cadastro/campo_cadastro.dart';

class TelaSenhaCadastro extends StatefulWidget {
  final String nome;
  final String email;
  final String telefone;
  final String cpfCnpj;
  final String cro;

  const TelaSenhaCadastro({
    super.key,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpfCnpj,
    required this.cro,
  });

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

  static const double _larguraMaxima = 480;

  @override
  void dispose() {
    _controladorSenha.dispose();
    _controladorConfirmar.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_carregando) return;

    setState(() => _carregando = true);

    final resultado = await ApiService.cadastrar(
      nome: widget.nome,
      email: widget.email,
      senha: _controladorSenha.text,
      telefone: widget.telefone,
      cpfCnpj: widget.cpfCnpj,
      cro: widget.cro,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado.temErro) {
      _mostrarErro(resultado.erro!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conta criada com sucesso! Faça login.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
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
                      const SizedBox(height: 8),

                      // Indicador de etapa
                      _IndicadorEtapa(etapaAtual: 1),
                      const SizedBox(height: 20),

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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Digite uma senha';
                          if (v.length < 8) {
                            return 'A senha deve ter pelo menos 8 caracteres';
                          }
                          // Exige pelo menos 1 letra e 1 número
                          if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                            return 'A senha deve conter pelo menos uma letra';
                          }
                          if (!RegExp(r'\d').hasMatch(v)) {
                            return 'A senha deve conter pelo menos um número';
                          }
                          return null;
                        },
                        sufixo: IconButton(
                          icon: Icon(
                            _ocultarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black45,
                          ),
                          onPressed: _carregando
                              ? null
                              : () => setState(
                                  () => _ocultarSenha = !_ocultarSenha,
                                ),
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
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirme sua senha';
                          }
                          if (v != _controladorSenha.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                        sufixo: IconButton(
                          icon: Icon(
                            _ocultarConfirmar
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black45,
                          ),
                          onPressed: _carregando
                              ? null
                              : () => setState(
                                  () => _ocultarConfirmar = !_ocultarConfirmar,
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Criar conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
  final int etapaAtual; // 0 ou 1
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
