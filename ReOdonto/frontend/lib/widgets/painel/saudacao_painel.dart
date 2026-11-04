import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';

// NOVO WIDGET: a saudação "Olá, Dr(a). Ana" estava montada dentro do
// _conteudo da telaMenu.dart. Agora é um widget próprio.

/// "Olá, Dr(a). <primeiro nome>" com o nome em azul.
class SaudacaoPainel extends StatelessWidget {
  /// Primeiro nome do dentista logado (pode ser vazio).
  final String primeiroNome;

  const SaudacaoPainel({super.key, required this.primeiroNome});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textoEscuro,
        ),
        children: [
          // "Dr(a)." porque o cadastro ainda não guarda o gênero do dentista.
          const TextSpan(text: 'Olá, Dr(a). '),
          TextSpan(
            text: primeiroNome,
            style: const TextStyle(color: AppColors.azulPrimario),
          ),
        ],
      ),
    );
  }
}
