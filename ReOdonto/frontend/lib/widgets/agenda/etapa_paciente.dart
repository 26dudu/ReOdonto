import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/mascaras.dart';


// Cadastro rápido: nome e telefone do paciente que chegou direto na clínica.
// Com "Abrir horário vago" ligado, o horário é criado sem paciente e fica
// disponível na agenda para um encaixe depois.

class EtapaPaciente extends StatelessWidget {
  final GlobalKey<FormState> chaveFormulario;
  final TextEditingController controladorNome;
  final TextEditingController controladorTelefone;
  final bool horarioVago;
  final ValueChanged<bool> onHorarioVagoAlterado;

  const EtapaPaciente({
    super.key,
    required this.chaveFormulario,
    required this.controladorNome,
    required this.controladorTelefone,
    required this.horarioVago,
    required this.onHorarioVagoAlterado,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: chaveFormulario,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: horarioVago,
              onChanged: onHorarioVagoAlterado,
              title: const Text(
                'Abrir horário vago',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Cria o horário sem paciente, pronto para um encaixe.',
                style: TextStyle(fontSize: 12, color: AppColors.textoCinza),
              ),
            ),
            const SizedBox(height: 8),
            if (!horarioVago) ...[
              const Text(
                'Paciente que chegou na clínica sem passar pelo WhatsApp/app.',
                style: TextStyle(fontSize: 13, color: AppColors.textoCinza),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controladorNome,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome do paciente'),
                validator: (valor) => (valor == null || valor.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controladorTelefone,
                keyboardType: TextInputType.phone,
                inputFormatters: [TelefoneInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(DDD) 9XXXX-XXXX',
                ),
                validator: (valor) {
                  final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digitos.length < 10) return 'Telefone inválido';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
