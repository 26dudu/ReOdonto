import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Resumo do agendamento (paciente + tipo de consulta), mostrado na
/// última etapa do modal de novo agendamento, antes de escolher a data.
class CartaoResumo extends StatelessWidget {
  final String paciente;
  final String consulta;

  const CartaoResumo({
    super.key,
    required this.paciente,
    required this.consulta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.preenchimentoCampo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordaCampo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo da consulta',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textoCinza,
            ),
          ),
          const SizedBox(height: 10),
          _LinhaResumo(icone: Icons.person_outline, label: 'Paciente', valor: paciente),
          const SizedBox(height: 6),
          _LinhaResumo(icone: Icons.medical_services_outlined, label: 'Consulta', valor: consulta),
        ],
      ),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;

  const _LinhaResumo({
    required this.icone,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: AppColors.textoCinza),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textoCinza,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 12, color: AppColors.textoEscuro),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}