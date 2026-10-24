import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Sombra suave usada pelos cartões brancos do painel.
const List<BoxShadow> sombraCartaoPainel = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4)),
];

/// Cartão do topo do painel: ícone num círculo colorido + título + valor.
/// Ex.: [$] Prejuízo evitado / R$ 8.450
class CartaoIndicador extends StatelessWidget {
  final IconData icone;
  final Color corIcone; // cor do ícone e do valor
  final String titulo;
  final String valor;

  const CartaoIndicador({
    super.key,
    required this.icone,
    required this.corIcone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$titulo: $valor',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.fundoCartao,
          borderRadius: BorderRadius.circular(20),
          boxShadow: sombraCartaoPainel,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: corIcone.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: corIcone, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textoEscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: corIcone,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
