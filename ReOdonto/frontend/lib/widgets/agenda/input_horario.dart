import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';


class InputHorario extends StatefulWidget {
  // Horário atualmente selecionado (vem de fora, do widget pai). Pode ser
  // nulo se o usuário ainda não escolheu nenhum horário.
  final TimeOfDay? horarioSelecionado;

  // Callback chamado sempre que hora ou minuto mudam, avisando o widget
  // pai qual horário foi escolhido.
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
  // Lista fixa de minutos permitidos: intervalos de 15 em 15.
  // Se um dia precisar mudar pra 30 em 30, basta trocar essa lista
  // para [0, 30].
  static const List<int> _minutosPermitidos = [0, 15, 30, 45];

  // Hora e minuto atualmente escolhidos nos dropdowns. Começam nulos
  // (nada selecionado) a não ser que já venha um horário de fora.
  int? _horaSelecionada;
  int? _minutoSelecionado;

  @override
  void initState() {
    super.initState();
    // Se já existe um horário vindo do widget pai, pré-seleciona os
    // dropdowns com ele.
    _horaSelecionada = widget.horarioSelecionado?.hour;
    _minutoSelecionado = widget.horarioSelecionado?.minute;
  }

  // Chamado sempre que a hora ou o minuto mudam num dos dropdowns.
  // Só emite o horário completo pro widget pai quando os dois já
  // estiverem preenchidos.
  void _atualizarHorario() {
    if (_horaSelecionada != null && _minutoSelecionado != null) {
      widget.onHorarioSelecionado(
        TimeOfDay(hour: _horaSelecionada!, minute: _minutoSelecionado!),
      );
    }
  }

  // Decoração compartilhada pelos dois dropdowns, pra manter o mesmo
  // visual (borda, preenchimento, etc) usado no resto do formulário.
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
      crossAxisAlignment: CrossAxisAlignment.start, // alinha tudo à esquerda
      children: [
        // Rótulo fixo acima dos dropdowns.
        const Text(
          'Horário',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 12), // espaçamento vertical

        Row(
          children: [
            // ---- Dropdown de hora (0 a 23) ----
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
                // Gera as opções de 0 a 23, formatadas com 2 dígitos (ex: "08").
                items: List.generate(24, (h) => h)
                    .map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text(h.toString().padLeft(2, '0')),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  setState(() => _horaSelecionada = valor);
                  _atualizarHorario();
                },
              ),
            ),
            const SizedBox(width: 12), // espaçamento entre os dois dropdowns

            // Dropdown de minuto (limitado aos intervalos permitidos
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
                // Usa a lista fixa de minutos permitidos (0, 15, 30, 45).
                items: _minutosPermitidos
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.toString().padLeft(2, '0')),
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

        // Texto avisando o intervalo permitido.
        Text(
          'Horários disponíveis de 15 em 15 minutos',
          style: TextStyle(fontSize: 12, color: AppColors.textoCinza),
        ),
      ],
    );
  }
}