import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color fundo = Color(0xFFEAF3FB); // Cor de fundo azul bem clara usada nas telas
  static const Color fundoCartao = Colors.white; // Cor de fundo dos cartões
  static const Color azulPrimario = Color(0xFF2F80ED); // Azul principal da marca
  static const Color azulClaro = Color(0xFF56CCF2); // Azul mais claro, usado em detalhes e no logo
  static const Color textoEscuro = Color(0xFF1B2733); // Cor escura usada nos textos principais

  // Cor de todo texto secundário. Contraste de 5,5:1 sobre branco (a WCAG pede no mínimo 4,5:1).
  static const Color textoCinza = Color(0xFF5B6B7D);

  static const Color bordaCampo = Color(0xFFE1E8F0); // Cor da borda dos campos de texto
  static const Color preenchimentoCampo = Color(0xFFF7FAFC); // Cor de fundo dos campos de texto

  // Cores de status (usadas pelo cartão e pela linha do tempo).
  // "confirmado"/"pendente" = cores vivas, para bolinhas e preenchimentos.
  // "...Texto" = versões mais escuras, com contraste suficiente para texto.
  static const Color confirmado = Color(0xFF1FAE7D);
  static const Color confirmadoTexto = Color(0xFF14795A);
  static const Color pendente = Color(0xFFF2994A);
  static const Color pendenteTexto = Color(0xFFA85400);
  static const Color estrela = Color(0xFFF2C94C);

  // Painel administrativo (tela Menu).
  static const Color painelTeal = Color(0xFF45C8C8); // barras do gráfico
  static const Color painelTealTexto = Color(0xFF148A8A); // texto/ícone (contraste)
  static const Color painelRoxo = Color(0xFF7C4DDB);
}
