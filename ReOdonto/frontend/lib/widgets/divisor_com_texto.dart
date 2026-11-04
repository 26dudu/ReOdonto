import 'package:flutter/material.dart';

// NOVO WIDGET: o divisor "—— ou ——" do login saiu da telaLogin.dart.
// Pode ser reaproveitado em qualquer tela com `DivisorComTexto('ou')`.

/// Linha horizontal dividida ao meio por um texto curto (ex.: "ou").
class DivisorComTexto extends StatelessWidget {
  final String texto;

  const DivisorComTexto(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFCBD5E0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8C9AAB)),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFCBD5E0))),
      ],
    );
  }
}
