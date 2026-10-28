import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

// =============================================================================
// widgets/agenda/etapa_consulta.dart  (etapa 2 do modal)
//
// Tipo de consulta em texto livre, mais o valor e a duração do horário.
// O valor alimenta o "prejuízo evitado" do painel; a duração é usada pelo
// backend para recusar horários que se sobrepõem.
// =============================================================================
class EtapaConsulta extends StatelessWidget {
  final TextEditingController controlador;
  final TextEditingController controladorValor;
  final TextEditingController controladorDuracao;

  /// Em um horário vago o tipo de consulta é opcional.
  final bool tipoOpcional;

  const EtapaConsulta({
    super.key,
    required this.controlador,
    required this.controladorValor,
    required this.controladorDuracao,
    this.tipoOpcional = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tipoOpcional
                ? 'Informe quanto vale este horário. O tipo de consulta é opcional.'
                : 'Digite o tipo de consulta:',
            style: const TextStyle(fontSize: 14, color: AppColors.textoCinza),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controlador,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: tipoOpcional ? 'Tipo de consulta (opcional)' : 'Tipo de consulta',
              hintText: 'Ex: Limpeza, Obturação, Extração',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controladorValor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    hintText: 'Ex: 200,00',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controladorDuracao,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Duração (min)',
                    hintText: '30',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "200,50" ou "200.50" -> 200.5. Devolve null se vazio ou inválido.
double? lerValorEmReais(String texto) {
  final limpo = texto.trim().replaceAll(',', '.');
  if (limpo.isEmpty) return null;
  return double.tryParse(limpo);
}
