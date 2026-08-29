import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class InputHorario extends StatefulWidget {
  final TimeOfDay? horarioSelecionado;
  final ValueChanged<TimeOfDay> onHorarioSelecionado;

  const InputHorario({
    super.key,
    this.horarioSelecionado,
    required this.onHorarioSelecionado,
  });

  @override
  State<InputHorario> createState() => _InputHorarioState();
}

class _InputHorarioState extends State<InputHorario> {
  late TextEditingController _controladorHorario;

  @override
  void initState() {
    super.initState();
    final horario = widget.horarioSelecionado ?? const TimeOfDay(hour: 9, minute: 0);
    _controladorHorario = TextEditingController(
      text: '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _controladorHorario.dispose();
    super.dispose();
  }

  void _validarEEmitirHorario() {
    final texto = _controladorHorario.text;
    
    // Extrai hora e minuto
    final partes = texto.split(':');
    if (partes.length != 2) return;

    final hora = int.tryParse(partes[0]) ?? 0;
    final minuto = int.tryParse(partes[1]) ?? 0;

    // Validação
    if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59) {
      return;
    }

    // Emite o horário
    widget.onHorarioSelecionado(TimeOfDay(hour: hora, minute: minuto));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horário',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controladorHorario,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
            LengthLimitingTextInputFormatter(5),
          ],
          onChanged: (_) => _validarEEmitirHorario(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.bordaCampo,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.bordaCampo,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.azulPrimario,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: AppColors.preenchimentoCampo,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            hintText: 'HH:MM',
            hintStyle: TextStyle(
              color: AppColors.textoCinza,
              fontSize: 16,
            ),
          ),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textoEscuro,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Digite no formato HH:MM (ex: 08:00, 14:30)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textoCinza,
          ),
        ),
      ],
    );
  }
}
