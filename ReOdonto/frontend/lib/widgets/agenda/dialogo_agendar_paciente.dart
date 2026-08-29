import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../theme/app_colors.dart';
import '../../utils/mascaras.dart';

/// Formulário rápido pra agendar um paciente que chegou direto na clínica
/// — sem passar pelo WhatsApp/app. Pede só nome e telefone; dia, horário
/// e valor já vêm do horário vago escolhido (mostrados aqui só como
/// confirmação visual pro dentista).
///
/// Retorna via `Navigator.pop` um `Map<String, String>` com `nome` e
/// `telefone`, ou `null` se o dentista cancelar.
class DialogoAgendarPaciente extends StatefulWidget {
  final Agendamento agendamento;

  const DialogoAgendarPaciente({super.key, required this.agendamento});

  @override
  State<DialogoAgendarPaciente> createState() =>
      _EstadoDialogoAgendarPaciente();
}

class _EstadoDialogoAgendarPaciente extends State<DialogoAgendarPaciente> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorTelefone = TextEditingController();

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorTelefone.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_chaveFormulario.currentState!.validate()) return;
    Navigator.of(context).pop({
      'nome': _controladorNome.text.trim(),
      'telefone': _controladorTelefone.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final agendamento = widget.agendamento;
    return AlertDialog(
      title: const Text('Agendar paciente'),
      content: Form(
        key: _chaveFormulario,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${agendamento.dia} às ${agendamento.horario}'
                '${agendamento.preco != null ? ' • ${formatarPreco(agendamento.preco!)}' : ''}',
                style: const TextStyle(
                  color: AppColors.textoCinza,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorNome,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome do paciente',
                ),
                validator: (valor) => (valor == null || valor.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controladorTelefone,
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.azulPrimario,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
