import 'package:flutter/material.dart'; 
import '../label.dart'; 


class BasicInfoFields extends StatelessWidget {
  final TextEditingController controladorTelefone; 
  final TextEditingController controladorNomeCompleto; 
  final TextEditingController controladorEmail;

  const BasicInfoFields({
    super.key,
    required this.controladorTelefone,
    required this.controladorNomeCompleto,
    required this.controladorEmail,
  });

  @override
  Widget build(BuildContext contexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        LabeledTextField(
          rotulo: 'Telefone',
          textoAjuda: 'Ex: (DDD) 9XXXX-XXXX',
          icone: Icons.phone_outlined,
          controlador: controladorTelefone,
          tipoTeclado: TextInputType.phone, 
        ),
        const SizedBox(height: 16), 
        LabeledTextField(
          rotulo: 'Nome Completo',
          textoAjuda: 'Ex: Arthur Fonseca Marechal',
          icone: Icons.person_outline,
          controlador: controladorNomeCompleto,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          rotulo: 'Email',
          textoAjuda: 'Digite seu email',
          icone: Icons.mail_outline,
          controlador: controladorEmail,
          tipoTeclado: TextInputType.emailAddress, 
        ),
      ],
    );
  }
}
