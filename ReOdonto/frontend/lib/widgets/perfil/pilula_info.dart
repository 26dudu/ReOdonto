import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// "Pílula" arredondada usada no topo do perfil para mostrar
/// avaliação e total de consultas.
class PilulaInfo extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool rotuloClicavel;

  const PilulaInfo({
    super.key,
    required this.rotulo,
    required this.valor,
    this.rotuloClicavel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: rotuloClicavel
                ? AppColors.azulPrimario
                : AppColors.textoCinza,
            decoration: rotuloClicavel
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.preenchimentoCampo,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.bordaCampo),
          ),
          alignment: Alignment.center,
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textoEscuro,
            ),
          ),
        ),
      ],
    );
  }
}
