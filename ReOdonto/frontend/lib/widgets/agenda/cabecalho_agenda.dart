import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';

// NOVO WIDGET: o título "Sua agenda" + a saudação "Olá, Dra. Fulana" estavam
// dentro do _conteudoDaAgenda da telaAgenda.dart.

/// Topo da agenda: título da página e saudação com o nome em azul.
class CabecalhoAgenda extends StatelessWidget {
  /// Nome do dentista logado (se vier null, mostra "Dentista").
  final String? nomeDentista;

  const CabecalhoAgenda({super.key, required this.nomeDentista});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da página.
        const Text(
          'Sua agenda',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 6),
        // Saudação com nome destacado em azul.
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textoEscuro,
            ),
            children: [
              const TextSpan(text: 'Olá, Dra. '),
              TextSpan(
                text: nomeDentista ?? 'Dentista',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulPrimario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
