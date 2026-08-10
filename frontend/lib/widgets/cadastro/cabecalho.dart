import 'package:flutter/material.dart'; 
import 'package:flutter_svg/flutter_svg.dart'; 
import '../../theme/app_colors.dart'; 

class SignupHeader extends StatelessWidget {
  final String titulo; 
  final String? subtitulo; 
  final bool mostrarLogo; 
  final bool logoNoTopo; 

  const SignupHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.mostrarLogo = true, 
    this.logoNoTopo = false, 
  });

  @override
  Widget build(BuildContext contexto) {
    final colunaTitulo = Column(
      mainAxisSize: MainAxisSize.min, 
      children: [
        RichText(
          textAlign: TextAlign.center, 
          text: TextSpan(
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textoEscuro,
            ),
            children: _destacarReOdonto(titulo), 
          ),
        ),
        if (subtitulo != null) ...[
         
          const SizedBox(height: 4), 
          Text(
            subtitulo!, 
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textoCinza,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    if (!mostrarLogo) return colunaTitulo; 

    if (logoNoTopo) {
      return Stack(
        
        clipBehavior: Clip.none, 
        children: [
          Center(child: colunaTitulo), 
          Positioned(
            right: 0,
            top: -4,
            child: SvgPicture.asset(
              'assets/icons/tooth-svgrepo-com.svg',
              width: 48,
              height: 48,
              colorFilter: const ColorFilter.mode(
                AppColors.azulPrimario,
                BlendMode.srcIn,
              ),
            ),
          ), 
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/tooth-svgrepo-com.svg',
          width: 44,
          height: 44,
          colorFilter: const ColorFilter.mode(
            AppColors.azulPrimario,
            BlendMode.srcIn,
          ),
        ), 
        const SizedBox(height: 10), 
        colunaTitulo,
      ],
    );
  }

  
  List<TextSpan> _destacarReOdonto(String texto) {
    const marcador = 'ReOdonto'; 
    final indice = texto.indexOf(marcador); 
    if (indice == -1) return [TextSpan(text: texto)]; 

    return [
      TextSpan(text: texto.substring(0, indice)), 
      TextSpan(
        text: marcador, 
        style: const TextStyle(color: AppColors.azulPrimario), 
      ),
      TextSpan(text: texto.substring(indice + marcador.length)), 
    ];
  }
}