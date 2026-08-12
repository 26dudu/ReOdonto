import 'package:flutter/material.dart'; 
import '../label_text.dart'; 


class SecurityInfoFields extends StatelessWidget {
  final TextEditingController controladorSenha;
  final TextEditingController controladorConfirmarSenha; 
  final bool ocultarSenha; 
  final bool ocultarConfirmarSenha; 
  final VoidCallback aoAlternarOcultarSenha; 
  final VoidCallback aoAlternarOcultarConfirmarSenha;

  const SecurityInfoFields({
    super.key,
    required this.controladorSenha,
    required this.controladorConfirmarSenha,
    required this.ocultarSenha,
    required this.ocultarConfirmarSenha,
    required this.aoAlternarOcultarSenha,
    required this.aoAlternarOcultarConfirmarSenha,
  });

  @override
  Widget build(BuildContext contexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          rotulo: 'Senha',
          textoAjuda: 'Digite sua senha',
          icone: Icons.lock_outline,
          controlador: controladorSenha,
          ehSenha: true, 
          ocultarTexto: ocultarSenha,
          aoAlternarOcultar: aoAlternarOcultarSenha,
        ),
        const SizedBox(height: 16), 
        LabeledTextField(
          rotulo: 'Confirme sua senha',
          textoAjuda: 'Digite sua senha',
          icone: Icons.lock_outline,
          controlador: controladorConfirmarSenha,
          ehSenha: true,
          ocultarTexto: ocultarConfirmarSenha,
          aoAlternarOcultar: aoAlternarOcultarConfirmarSenha,
        ),
      ],
    );
  }
}
