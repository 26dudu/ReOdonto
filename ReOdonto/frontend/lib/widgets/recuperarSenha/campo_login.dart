import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoLogin extends StatelessWidget {
  final TextEditingController controller;

  final String hintText;

  final bool enabled;

  final bool obscureText;

  final TextInputType keyboardType;

  final ValueChanged<String>? onChanged;

  final Widget? suffixIcon;

  final Widget? prefixIcon;

  final List<TextInputFormatter>? formatadores;

  const CampoLogin({
    super.key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.formatadores,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,

      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: formatadores,

      onChanged: onChanged,

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(color: Colors.black26),

        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

      ),
    );
  }
}
