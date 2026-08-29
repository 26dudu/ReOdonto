import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CampoCadastro extends StatelessWidget {
  final String rotulo;
  final String hint;
  final IconData icone;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType tipo;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final Widget? sufixo;

  const CampoCadastro({
    super.key,
    required this.rotulo,
    required this.hint,
    required this.icone,
    required this.controller,
    this.validator,
    this.tipo = TextInputType.text,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.sufixo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: tipo,
          inputFormatters: inputFormatters,
          validator: validator,
          obscureText: obscureText,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            prefixIcon: Icon(icone, color: const Color(0xFF58606A)),
            suffixIcon: sufixo,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}