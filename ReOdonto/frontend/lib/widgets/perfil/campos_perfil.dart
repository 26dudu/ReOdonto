import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';


class CampoPerfil extends StatelessWidget {
  final String rotulo;
  final TextEditingController controlador;
  final bool somenteLeitura;

  const CampoPerfil({
    super.key,
    required this.rotulo,
    required this.controlador,
    this.somenteLeitura = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textoCinza,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          readOnly: somenteLeitura,
          style: TextStyle(
            fontSize: 13,
            color: somenteLeitura ? AppColors.textoCinza : AppColors.textoEscuro,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: somenteLeitura ? AppColors.bordaCampo : AppColors.fundoCartao,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.bordaCampo),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.bordaCampo),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.azulPrimario),
            ),
          ),
        ),
      ],
    );
  }
}


class CampoEstatico extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color? corValor;

  const CampoEstatico({
    super.key,
    required this.rotulo,
    required this.valor,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textoCinza,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.fundoCartao,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.bordaCampo),
          ),
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: corValor ?? AppColors.textoEscuro,
            ),
          ),
        ),
      ],
    );
  }
}