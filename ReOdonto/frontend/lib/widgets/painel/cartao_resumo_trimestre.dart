import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'cartao_indicador.dart';

/// Linha do resumo: ícone + rótulo à esquerda, valor à direita.
class LinhaResumoTrimestre {
  final IconData icone;
  final String rotulo;
  final String valor;

  const LinhaResumoTrimestre({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });
}

/// Cartão "Resumo dos últimos 3 meses" (título + cartão branco com as linhas).
class CartaoResumoTrimestre extends StatelessWidget {
  final List<LinhaResumoTrimestre> linhas;
  const CartaoResumoTrimestre({super.key, required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo dos últimos 3 meses',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.fundoCartao,
            borderRadius: BorderRadius.circular(20),
            boxShadow: sombraCartaoPainel,
          ),
          child: Column(
            children: [
              for (int i = 0; i < linhas.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _Linha(linha: linhas[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  final LinhaResumoTrimestre linha;
  const _Linha({required this.linha});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(linha.icone, size: 17, color: AppColors.azulClaro),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            linha.rotulo,
            style: const TextStyle(fontSize: 13, color: AppColors.textoEscuro),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          linha.valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textoEscuro,
          ),
        ),
      ],
    );
  }
}
