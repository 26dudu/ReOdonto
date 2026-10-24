// Material Design.
import 'package:flutter/material.dart';
// Fornece FilteringTextInputFormatter (filtros de digitação).
import 'package:flutter/services.dart';
// Pacote de botões "Entrar com Google" etc. Está importado, mas NÃO é usado neste arquivo (pode ser removido).
import 'package:sign_in_button/sign_in_button.dart';
// Paleta de cores.
import '../theme/app_colors.dart';
// Máscaras de CPF/CNPJ, telefone e CRO.
import '../utils/mascaras.dart';
// Cabeçalho do cadastro (SignupHeader).
import '../widgets/cadastro/cabecalhoCadastro.dart';
// Campo de formulário do cadastro (CampoCadastro).
import '../widgets/cadastro/campo_cadastro.dart';
// Próxima etapa do cadastro (criar senha).
import 'telaSenhaCadastro.dart';
// Botão principal.
import '../widgets/botao_principal.dart';

// TELA 1 DO CADASTRO DE DENTISTA: dados pessoais (nome, e-mail, telefone, CPF/CNPJ, CRO).
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _EstadoSignupPage();
}

class _EstadoSignupPage extends State<SignupPage> {
  final _formKey =
      GlobalKey<
        FormState
      >(); // Chave global que conecta e controla todos os campos do formulário.
  // É usada para acionar a validação de todos os campos de uma só vez (ex: testar se o email ou CPF estão corretos)
  // e fazer aparecer as mensagens de erro em vermelho abaixo deles.

  // Um controller para cada campo, para ler o que foi digitado.
  final _controladorNome = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorTelefone = TextEditingController();
  final _controladorCpfCnpj = TextEditingController();
  final _controladorCro = TextEditingController();

  // Largura máxima do cartão do formulário.
  static const double _larguraMaxima = 480;

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

  // Validator do nome: devolve mensagem de erro (String) ou null se estiver ok.
  String? _validarNome(String? nomeDigitado) {
    // Vazio (ou só espaços).
    if (nomeDigitado == null || nomeDigitado.trim().isEmpty)
      return 'Preencha o nome completo';
    // Muito curto.
    if (nomeDigitado.trim().length < 3)
      return 'Nome deve ter pelo menos 3 caracteres';
    return null;
  }

  // Validator do e-mail.
  String? _validarEmail(String? emailDigitado) {
    if (emailDigitado == null || emailDigitado.trim().isEmpty)
      return 'Preencha o email';
    // Expressão regular: texto@dominio.xx (letras, números, ponto, + e - antes do @).
    final regex = RegExp(
      r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$',
      // Ignora maiúsculas/minúsculas.
      caseSensitive: false,
    );
    if (!regex.hasMatch(emailDigitado.trim()))
      return 'Email inválido'; // Se o texto não bater com a regra, dá erro
    return null;
  }

  // Validator do telefone.
  String? _validarTelefone(String? telefoneDigitado) {
    if (telefoneDigitado == null || telefoneDigitado.trim().isEmpty)
      return 'Preencha o telefone';
    // Remove tudo que não é dígito (parênteses, espaço, hífen).
    final digitos = telefoneDigitado.replaceAll(RegExp(r'\D'), '');
    // Telefone brasileiro: 10 (fixo) ou 11 (celular) dígitos.
    if (digitos.length < 10 || digitos.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  // Validator do CPF/CNPJ: decide pelo tamanho qual algoritmo usar.
  String? _validarCpfCnpj(String? cpfcnpjDigitado) {
    if (cpfcnpjDigitado == null || cpfcnpjDigitado.trim().isEmpty)
      return 'Preencha o CPF ou CNPJ';
    // Só os números.
    final digitos = cpfcnpjDigitado.replaceAll(RegExp(r'\D'), '');
    // 11 dígitos = CPF.
    if (digitos.length == 11) {
      if (!_validarCpf(digitos)) return 'CPF inválido';
      // 14 dígitos = CNPJ.
    } else if (digitos.length == 14) {
      if (!_validarCnpj(digitos)) return 'CNPJ inválido';
    } else {
      // Qualquer outro tamanho é inválido.
      return 'Digite um CPF (11 dígitos) ou CNPJ (14 dígitos)';
    }
    return null;
  }

  // Confere os dígitos verificadores de um CPF (recebe só números).
  bool _validarCpf(String cpf) {
    // Lógica matemática oficial para validar um CPF real
    // Rejeita tamanho errado e sequências repetidas (cpf[0] * 11 repete o 1º dígito 11 vezes).
    if (cpf.length != 11 || cpf == cpf[0] * 11) return false;
    // pos = 9 valida o 1º dígito verificador; pos = 10 valida o 2º.
    for (
      int posicaoDoVerificador = 9;
      posicaoDoVerificador <= 10;
      posicaoDoVerificador++
    ) {
      // Acumulador da soma ponderada.
      int soma = 0;
      for (
        int posicaoDoDigito = 0;
        posicaoDoDigito < posicaoDoVerificador;
        posicaoDoDigito++
      ) {
        // Multiplica cada dígito pelo peso (pos+1-i): 10,9,8... ou 11,10,9...
        soma += int.parse(cpf[posicaoDoDigito]) * (posicaoDoVerificador + 1 - posicaoDoDigito);
      }
      // Fórmula do dígito: (soma*10 mod 11), e 10 vira 0 (% 10).
      final digito = (soma * 10 % 11) % 10;
      // Se não bate com o dígito informado, é inválido.
      if (digito != int.parse(cpf[posicaoDoVerificador])) return false;
    }
    return true;
  }

  // Confere os dígitos verificadores de um CNPJ (recebe só números).
  bool _validarCnpj(String cnpj) {
    // Lógica matemática oficial para validar um CNPJ real
    // Rejeita tamanho errado e dígitos todos iguais.
    if (cnpj.length != 14 || cnpj == cnpj[0] * 14) return false;
    // Pesos oficiais para o 1º dígito verificador (12 números).
    final p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    // Pesos oficiais para o 2º dígito verificador (13 números).
    final p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    // Itera sobre pares (pesos, posição do dígito). "Record" do Dart 3: (p1, 12) e (p2, 13).
    for (final regra in [(p1, 12), (p2, 13)]) {
      // $1 = primeiro item do par (lista de pesos).
      final pesos = regra.$1;
      // $2 = segundo item do par (posição do dígito verificador).
      final pos = regra.$2;
      int soma = 0;
      for (int posicao = 0; posicao < pos; posicao++) {
        // Dígito × peso correspondente.
        soma += int.parse(cnpj[posicao]) * pesos[posicao];
      }
      // Resto da divisão por 11.
      final resto = soma % 11;
      // Regra: resto menor que 2 → dígito 0; senão 11 - resto.
      final digito = resto < 2 ? 0 : 11 - resto;
      // Compara com o dígito real do CNPJ.
      if (digito != int.parse(cnpj[pos])) return false;
    }
    return true;
  }

  // Botão "Continuar": valida e avança para a tela de senha.
  void _continuar() {
    // Se algum campo estiver inválido, mostra os erros e não avança.
    if (!_formKey.currentState!.validate()) return;

    // Empilha a próxima tela passando os dados digitados.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaSenhaCadastro(
          // trim() tira espaços sobrando de cada valor.
          nome: _controladorNome.text.trim(),
          email: _controladorEmail.text.trim(),
          telefone: _controladorTelefone.text.trim(),
          cpfCnpj: _controladorCpfCnpj.text.trim(),
          cro: _controladorCro.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo azul claro padrão.
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        // Rolagem vertical.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              // Limita a largura do cartão.
              constraints: const BoxConstraints(maxWidth: _larguraMaxima),
              // Cartão branco com sombra.
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.fundoCartao,
                  // Cantos arredondados de 20.
                  borderRadius: BorderRadius.circular(20),
                  // Sombra suave.
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                // Form agrupa os campos para a validação conjunta.
                child: Form(
                  key: _formKey, //Atribui a chave de formulário criada
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Linha com o botão de voltar.
                      Row(
                        children: [
                          IconButton(
                            // Volta para o login.
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(), //voltar a tela login
                            // Sem espaçamentos extras do botão.
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
                      // Índice 0 = primeira etapa ativa.
                      _IndicadorEtapa(
                        etapaAtual: 0,
                      ), //widget da animação de trocar a pagina
                      const SizedBox(height: 16),

                      // Título + subtítulo (com logo, pois mostrarLogo não foi desativado).
                      const SignupHeader(
                        // widget personalizado de cabeçalho
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
                        // Impede começar o texto com espaços (^\s+ = espaços no início).
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
                        // Teclado de e-mail no celular.
                        tipo: TextInputType.emailAddress,
                        // Bloqueia qualquer espaço (\s) no e-mail.
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
                        validator: _validarCpfCnpj,
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

                      // CRO (opcional)
                      // Sem validator: o campo é opcional.
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

// Desenha as barrinhas do indicador de etapa (mesmo widget existe em telaSenhaCadastro.dart).
class _IndicadorEtapa extends StatelessWidget {
  // Índice da etapa ativa (0 ou 1).
  final int etapaAtual;
  const _IndicadorEtapa({required this.etapaAtual});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // Gera 2 barrinhas.
      children: List.generate(2, (i) {
        // Barrinha ativa = a da etapa atual.
        final ativa = i == etapaAtual;
        // Container animado: muda largura e cor suavemente.
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
