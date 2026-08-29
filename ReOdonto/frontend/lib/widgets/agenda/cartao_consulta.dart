import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../theme/app_colors.dart';

// Cores de status específicas desse card — não fazem parte da paleta
const Color _corConfirmado = Color(0xFF1FAE7D);
const Color _corPendente = Color(0xFFF2994A);
const Color _corEstrela = Color(0xFFF2C94C);


class CartaoConsulta extends StatelessWidget {
  final Agendamento consulta;
  final VoidCallback? onConfirmar;
  final VoidCallback? onCancelar;
  final VoidCallback? onAgendar;

  const CartaoConsulta({
    super.key,
    required this.consulta,
    this.onConfirmar,
    this.onCancelar,
    this.onAgendar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fundoCartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordaCampo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linhaPaciente(),
          const SizedBox(height: 6),
          _linha('Dia:', consulta.dia),
          const SizedBox(height: 4),
          _linha('Horário:', consulta.horario),
          if (consulta.preco != null) ...[
            const SizedBox(height: 4),
            _linha('Preço:', formatarPreco(consulta.preco!)),
          ],
          if (!consulta.vago) ...[
            const SizedBox(height: 4),
            _linhaStatus(),
          ],
          const SizedBox(height: 12),
          _botao(),
        ],
      ),
    );
  }

  Widget _linhaPaciente() {
    if (consulta.vago) {
      return const Text(
        'Paciente: Indefinido',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textoEscuro,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textoEscuro,
        ),
        children: [
          TextSpan(text: 'Paciente: ${consulta.paciente}'),
          if (consulta.avaliacaoPaciente != null)
            TextSpan(
              text:
                  ' ${consulta.avaliacaoPaciente!.toStringAsFixed(1).replaceAll('.', ',')} ★',
              style: const TextStyle(color: _corEstrela),
            ),
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
        children: [
          TextSpan(text: '$rotulo '),
          TextSpan(
            text: valor,
            style: const TextStyle(
              color: AppColors.textoEscuro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaStatus() {
    final cor = consulta.status == 'Confirmado' ? _corConfirmado : _corPendente;
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppColors.textoCinza),
        children: [
          const TextSpan(text: 'Status: '),
          TextSpan(
            text: consulta.status,
            style: TextStyle(color: cor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _botao() {
    final String texto;
    final VoidCallback? aoTocar;
    if (consulta.vago) {
      texto = 'Agendar Paciente';
      aoTocar = onAgendar;
    } else if (consulta.status == 'Pendente') {
      texto = 'Confirmar Atendimento';
      aoTocar = onConfirmar;
    } else {
      texto = 'Deseja Cancelar?';
      aoTocar = onCancelar;
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulPrimario,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}