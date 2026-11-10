import 'package:flutter/material.dart';
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
  static const List<int> _minutosPermitidos = [0, 15, 30, 45];

  int? _horaSelecionada;
  int? _minutoSelecionado;

  @override
  void initState() {
    super.initState();
    _horaSelecionada = widget.horarioSelecionado?.hour;
    _minutoSelecionado = widget.horarioSelecionado?.minute;
  }

  void _atualizarHorario() {
    if (_horaSelecionada != null && _minutoSelecionado != null) {
      widget.onHorarioSelecionado(
        TimeOfDay(hour: _horaSelecionada!, minute: _minutoSelecionado!),
      );
    }
  }

  InputDecoration _decoracaoDropdown(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.bordaCampo),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.bordaCampo),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.azulPrimario, width: 2),
      ),
      filled: true,
      fillColor: AppColors.preenchimentoCampo,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
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

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _horaSelecionada,
                isExpanded: true,
                decoration: _decoracaoDropdown('Hora'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoEscuro,
                ),
                hint: const Text('--'),
                items: List.generate(24, (hora) => hora)
                    .map(
                      (hora) => DropdownMenuItem(
                        value: hora,
                        child: Text(hora.toString().padLeft(2, '0')),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  setState(() => _horaSelecionada = valor);
                  _atualizarHorario();
                },
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: DropdownButtonFormField<int>(
                value: _minutoSelecionado,
                isExpanded: true,
                decoration: _decoracaoDropdown('Minuto'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoEscuro,
                ),
                hint: const Text('--'),
                items: _minutosPermitidos
                    .map(
                      (minuto) => DropdownMenuItem(
                        value: minuto,
                        child: Text(minuto.toString().padLeft(2, '0')),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  setState(() => _minutoSelecionado = valor);
                  _atualizarHorario();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8), 

        Text(
          'Horários disponíveis de 15 em 15 minutos',
          style: TextStyle(fontSize: 12, color: AppColors.textoCinza),
        ),
      ],
    );
  }
}
