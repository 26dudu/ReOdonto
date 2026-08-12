import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class LabeledTextField extends StatelessWidget {
  final String rotulo;
  final String textoAjuda;
  final IconData icone;
  final bool ehSenha;
  final bool ocultarTexto;
  final VoidCallback? aoAlternarOcultar;
  final TextEditingController? controlador;
  final TextInputType tipoTeclado;
  final List<TextInputFormatter>? inputFormatters; // <-- novo
  final bool somenteLeitura;

  const LabeledTextField({
    super.key,
    required this.rotulo,
    required this.textoAjuda,
    required this.icone,
    this.ehSenha = false,
    this.ocultarTexto = false,
    this.aoAlternarOcultar,
    this.controlador,
    this.tipoTeclado = TextInputType.text,
    this.inputFormatters,
    this.somenteLeitura = false,
  });

  @override
  Widget build(BuildContext contexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: AppColors.textoEscuro,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          obscureText: ehSenha ? ocultarTexto : false,
          keyboardType: tipoTeclado,
          inputFormatters: inputFormatters,
          readOnly: somenteLeitura,
          style: TextStyle(
            fontSize: 14,
            color: somenteLeitura
                ? AppColors.textoCinza   // texto mais apagado quando bloqueado
                : AppColors.textoEscuro,
          ),
          decoration: InputDecoration(
            hintText: textoAjuda,
            hintStyle: const TextStyle(
              color: AppColors.textoCinza,
              fontSize: 14,
            ),
            filled: true,
            fillColor: somenteLeitura
                ? AppColors.bordaCampo   // fundo cinza quando bloqueado
                : AppColors.preenchimentoCampo,
            prefixIcon: Icon(
              icone,
              size: 19,
              color: AppColors.textoCinza,
            ),
            suffixIcon: ehSenha
                ? IconButton(
                    icon: Icon(
                      ocultarTexto
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.textoCinza,
                    ),
                    onPressed: aoAlternarOcultar,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.bordaCampo),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.bordaCampo),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.azulPrimario),
            ),
          ),
        ),
      ],
    );
  }
}
