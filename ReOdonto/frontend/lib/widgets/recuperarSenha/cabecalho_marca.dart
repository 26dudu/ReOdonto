import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';

class CabecalhoMarca extends StatelessWidget {
  const CabecalhoMarca({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape
                .circle,
            border: Border.all(
              color: const Color(0xFFD0E2FF),
              width: 2,
            ),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/tooth-svgrepo-com.svg',
              width:
                  32,
              height: 32,
              colorFilter: const ColorFilter.mode(
                AppColors.azulPrimario,
                BlendMode
                    .srcIn,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00C1A2),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'AGENDA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight
                    .w900,
                color: Color(0xFF1C2434),
                height: 0.9,
              ),
            ),
            Text(
              'CHEIA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C2434),
              ),
            ),
            Text(
              'CLÍNICAS ODONTOLÓGICAS - AGENDAMENTO ONLINE',
              style: TextStyle(fontSize: 6, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
