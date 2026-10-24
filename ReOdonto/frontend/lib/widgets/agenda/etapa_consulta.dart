import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// =============================================================================
// widgets/agenda/etapa_consulta.dart  (etapa 2 do modal)
//
// Campo de texto livre para o dentista digitar o tipo de consulta
// ("Ex: Limpeza, Obturação, Extração"). Não há mais lista de opções para marcar.
// =============================================================================
class EtapaConsulta extends StatelessWidget {
  final TextEditingController controlador;

  const EtapaConsulta({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Digite o tipo de consulta:',
            style: TextStyle(fontSize: 14, color: AppColors.textoCinza),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controlador,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tipo de consulta',
              hintText: 'Ex: Limpeza, Obturação, Extração',
            ),
          ),
        ],
      ),
    );
  }
}
