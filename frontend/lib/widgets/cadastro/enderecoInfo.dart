import 'package:flutter/material.dart';
import '../label.dart';


class AddressInfoFields extends StatelessWidget {
  final TextEditingController controladorCpf; 
  final TextEditingController controladorCep; 
  final TextEditingController controladorRua; 
  final TextEditingController controladorBairro; 
  final TextEditingController controladorNumero; 

  const AddressInfoFields({
    super.key,
    required this.controladorCpf,
    required this.controladorCep,
    required this.controladorRua,
    required this.controladorBairro,
    required this.controladorNumero,
  });

  @override
  Widget build(BuildContext contexto) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        LabeledTextField(
          rotulo: 'CPF',
          textoAjuda: 'Ex: 123.456.789.10',
          icone: Icons.badge_outlined,
          controlador: controladorCpf,
          tipoTeclado: TextInputType.number, 
        ),
        const SizedBox(height: 16), 
        LabeledTextField(
          rotulo: 'Cep',
          textoAjuda: 'Ex: 30150-380',
          icone: Icons.location_on_outlined,
          controlador: controladorCep,
          tipoTeclado: TextInputType.number,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          rotulo: 'Rua',
          textoAjuda: 'Ex: Rua Itajubá',
          icone: Icons.signpost_outlined,
          controlador: controladorRua,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          rotulo: 'Bairro',
          textoAjuda: 'Ex: Esmeralda',
          icone: Icons.map_outlined,
          controlador: controladorBairro,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          rotulo: 'Número',
          textoAjuda: 'Ex: 223',
          icone: Icons.numbers_outlined,
          controlador: controladorNumero,
          tipoTeclado: TextInputType.number,
        ),
      ],
    );
  }
}
