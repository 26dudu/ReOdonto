import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Card selecionável genérico — usado nas listas de opções do modal de
/// novo agendamento (ex: tipo de consulta).
class CartaoSelecao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String? descricao;
  final bool selecionado;
  final VoidCallback onTap;

  const CartaoSelecao({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.descricao,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado
              ? AppColors.azulPrimario.withOpacity(0.08)
              : AppColors.preenchimentoCampo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? AppColors.azulPrimario : AppColors.bordaCampo,
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selecionado ? AppColors.azulPrimario : AppColors.textoEscuro,
                    ),
                  ),
                  if (subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
                    ),
                  ],
                  if (descricao != null && descricao!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      descricao!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selecionado ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selecionado ? AppColors.azulPrimario : AppColors.bordaCampo,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}