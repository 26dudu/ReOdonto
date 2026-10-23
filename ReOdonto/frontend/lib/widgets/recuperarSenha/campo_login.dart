import 'package:flutter/material.dart'; // widgets básicos do Flutter (TextField, InputDecoration, etc)

// =============================================================================
// Campo de Login
// Campo de texto no estilo usado nas telas de autenticação (login,
// redefinir senha, nova senha): fundo branco, borda cinza-azulada clara,
// sem rótulo acima (só hintText) e sem ícone de prefixo por padrão.
//
// Antes desse widget existir, o mesmo bloco de InputDecoration (borda,
// preenchimento, padding) estava copiado em 5 campos diferentes, espalhados
// em 3 arquivos. Agora existe uma única vez aqui, e cada campo vira uma
// chamada de poucas linhas ao CampoLogin.
// =============================================================================

// StatelessWidget porque o próprio CampoLogin não guarda nenhum estado
// interno — quem guarda o texto digitado é o TextEditingController
// (controller) que vem de fora, do widget pai (a tela que usa o CampoLogin).
class CampoLogin extends StatelessWidget {
  // Controller que gerencia o texto digitado no campo (ler, limpar,
  // escutar mudanças). É obrigatório (required) porque sem ele o campo
  // não teria como ser lido pelo widget pai.
  final TextEditingController controller;

  // Texto de exemplo mostrado dentro do campo quando ele está vazio
  // (ex: "Digite seu email", "Nova Senha"). Também obrigatório, já que
  // esse widget não tem rótulo (label) acima do campo — o hintText é a
  // única indicação do que deve ser digitado ali.
  final String hintText;

  // Controla se o campo pode receber toque/digitação. Tem valor padrão
  // `true` (habilitado) — as telas passam `false` enquanto uma
  // requisição está em andamento, pra travar os campos.
  final bool enabled;

  // Controla se o texto digitado aparece escondido (bolinhas, tipo senha)
  // ou visível. Valor padrão `false` (texto visível) — só os campos de
  // senha passam `true`.
  final bool obscureText;

  // Tipo de teclado que o sistema operacional deve abrir ao focar o
  // campo (ex: teclado com "@" fácil de achar pra email, teclado
  // numérico pra telefone). Valor padrão é o teclado de texto comum.
  final TextInputType keyboardType;

  // Callback opcional chamado toda vez que o texto do campo muda. Usado,
  // por exemplo, na tela de nova senha, pra recalcular a checklist de
  // requisitos a cada tecla digitada. Como é opcional (`?`), campos que
  // não precisam reagir a mudanças (como o de e-mail) simplesmente não
  // passam esse parâmetro.
  final ValueChanged<String>? onChanged;

  // Widget opcional mostrado do lado DIREITO do campo — por exemplo, o
  // ícone de olho (mostrar/ocultar senha) ou o botão de reenviar código.
  // Como é opcional, campos simples (como o de e-mail) não passam nada
  // aqui e o campo fica sem nenhum ícone à direita.
  final Widget? suffixIcon;

  // Widget opcional mostrado do lado ESQUERDO do campo — por exemplo, o
  // ícone de envelope no campo de e-mail da tela de login. Nas telas de
  // redefinir senha, os campos não usam esse parâmetro (ficam sem ícone
  // à esquerda), seguindo o visual do Figma daquelas telas.
  final Widget? prefixIcon;

  // Construtor: define quais parâmetros são obrigatórios (`required`) e
  // quais têm valor padrão. `super.key` repassa a chave pro widget pai,
  // como em qualquer widget do Flutter.
  const CampoLogin({
    super.key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
  });

  // Método build: monta o TextField de verdade, usando os parâmetros
  // recebidos acima pra configurar o comportamento e a aparência.
  @override
  Widget build(BuildContext context) {
    return TextField(
      // Conecta o controller recebido — é ele quem de fato guarda e
      // expõe o texto digitado pro widget pai (a tela) poder ler depois.
      controller: controller,

      // Repassa direto os parâmetros recebidos pro TextField nativo do
      // Flutter, que já sabe o que fazer com cada um deles.
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,

      // Se `onChanged` foi passado pelo widget pai, o TextField vai
      // chamá-lo a cada mudança de texto. Se não foi passado (é `null`),
      // o TextField simplesmente não reage a mudanças — comportamento
      // padrão de campo "só leitura de valor final".
      onChanged: onChanged,

      // decoration é onde fica toda a aparência visual do campo: borda,
      // cor de fundo, ícones, texto de exemplo, espaçamento interno.
      decoration: InputDecoration(
        // O texto de placeholder, repassado do parâmetro hintText.
        hintText: hintText,

        // Cor do texto de placeholder: cinza bem clarinho (26 = baixa
        // opacidade em hexadecimal), pra ficar visualmente "apagado" e
        // não competir com o texto real que o usuário digitar.
        hintStyle: const TextStyle(color: Colors.black26),

        // Os ícones opcionais das pontas do campo — se algum dos dois
        // não foi passado pelo widget pai (é null), o Flutter
        // simplesmente não desenha nada naquele lado.
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,

        // filled + fillColor: pinta o fundo do campo de branco sólido
        // (em vez de transparente, que é o padrão do TextField).
        filled: true,
        fillColor: Colors.white,

        // Espaçamento interno do campo (entre a borda e o texto/ícones),
        // igual em cima/embaixo (vertical) e nos lados (horizontal).
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),

        // Borda padrão do campo (usada como base/fallback).
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // cantos arredondados
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)), // cinza-azulado clarinho
        ),

        // Borda mostrada quando o campo está habilitado mas SEM foco
        // (ou seja, no estado "normal" de repouso, antes/depois do
        // usuário clicar nele). Mesma cor da borda padrão acima —
        // definida separadamente porque o Flutter usa estados diferentes
        // (enabledBorder, focusedBorder, errorBorder, etc) pra cada
        // situação visual do campo.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        // Repare que não existe um `focusedBorder` customizado aqui —
        // isso significa que, quando o usuário clica no campo, o Flutter
        // usa a cor padrão do tema do app pra desenhar a borda de foco
        // (normalmente a cor primária definida lá no MaterialApp).
      ),
    );
  }
}