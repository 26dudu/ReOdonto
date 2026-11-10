import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../theme/app_colors.dart';

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
    final tipo = consulta.tipoConsulta;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordaCampo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(),
          if (tipo != null && tipo.isNotEmpty) ...[
            const SizedBox(height: 6),
            _linha('Consulta:', tipo),
          ],
          if (consulta.preco != null) ...[
            const SizedBox(height: 4),
            _linha('Preço:', formatarPreco(consulta.preco!)),
          ],
          if (!consulta.vago) ...[
            const SizedBox(height: 10),
            _pilulaStatus(),
          ],
          ..._acoes(),
        ],
      ),
    );
  }

  Widget _titulo() {
    if (consulta.vago) {
      return const Text(
        'Horário vago',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textoEscuro,
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textoEscuro,
        ),
        children: [
          TextSpan(text: consulta.paciente),
          if (consulta.avaliacaoPaciente != null)
            TextSpan(
              text:
                  ' ${consulta.avaliacaoPaciente!.toStringAsFixed(1).replaceAll('.', ',')} ★',
              style: const TextStyle(color: AppColors.estrela),
            ),
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.textoCinza),
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

  Widget _pilulaStatus() {
    final concluido = consulta.concluido;
    final corFundo = concluido ? AppColors.confirmado : AppColors.pendente;
    final corTexto =
        concluido ? AppColors.confirmadoTexto : AppColors.pendenteTexto;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        consulta.rotuloStatus,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: corTexto,
        ),
      ),
    );
  }

  List<Widget> _acoes() {
    if (consulta.vago) {
      return [const SizedBox(height: 12), _botao('Agendar Paciente', onAgendar)];
    }
    if (!consulta.emAberto) return const [];
    return [
      const SizedBox(height: 12),
      _botao('Confirmar Atendimento', onConfirmar),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onCancelar,
          style: TextButton.styleFrom(foregroundColor: AppColors.textoCinza),
          child: const Text(
            'Cancelar consulta',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ];
  }

  Widget _botao(String texto, VoidCallback? aoTocar) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulPrimario,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
