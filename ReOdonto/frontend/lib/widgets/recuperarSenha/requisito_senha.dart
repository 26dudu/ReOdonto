import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';
import '../../../../../../../utils/validadores.dart';

class RequisitoSenha extends StatelessWidget {
  final bool atendido;
  final String texto;

  const RequisitoSenha({super.key, required this.atendido, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          atendido ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: atendido ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            color: atendido ? AppColors.textoEscuro : AppColors.textoCinza,
          ),
        ),
      ],
    );
  }
}

class ChecklistRequisitosSenha extends StatelessWidget {
  final String senha;

  const ChecklistRequisitosSenha({super.key, required this.senha});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Obrigatório:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E5FD8),
          ),
        ),
        const SizedBox(height: 6),
        RequisitoSenha(
          atendido: senhaTemCaractereEspecial(senha),
          texto: 'Um caractere especial',
        ),
        const SizedBox(height: 4),
        RequisitoSenha(
          atendido: senhaTemMinimoCaracteres(senha),
          texto: 'Mínimo de 8 caracteres',
        ),
        const SizedBox(height: 4),
        RequisitoSenha(
          atendido: senhaTemMaiusculaMinusculaNumero(senha),
          texto: 'Letras maiúsculas, minúsculas e um número',
        ),
      ],
    );
  }
}
