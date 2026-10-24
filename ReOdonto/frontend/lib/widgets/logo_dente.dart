import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// Círculo branco com o ícone do dente.
/// Antes estava copiado em telaLogin, telaAgenda e telaPerfil.
class LogoDente extends StatelessWidget {
  const LogoDente({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD0E2FF), width: 2),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/tooth-svgrepo-com.svg',
          width: 32,
          height: 32,
          colorFilter: const ColorFilter.mode(
            AppColors.azulPrimario,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
