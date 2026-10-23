import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../theme/app_colors.dart';

// Cartão de um agendamento. O botão depende do estado:
//   vago -> "Agendar Paciente" | Pendente -> "Confirmar Atendimento" |
//   demais -> "Deseja Cancelar?"
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
          const SizedBox(height: 12),
          _botao(),
        ],
      ),
    );
  }

  /// Nome do paciente (com nota, se houver) ou "Horário vago".
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

  /// Linha "Rótulo: valor" (rótulo cinza, valor escuro).
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

  /// "Pílula" colorida com o status (Confirmado = verde, resto = laranja).
  Widget _pilulaStatus() {
    final confirmado = consulta.status == 'Confirmado';
    final corFundo = confirmado ? AppColors.confirmado : AppColors.pendente;
    final corTexto =
        confirmado ? AppColors.confirmadoTexto : AppColors.pendenteTexto;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        consulta.status ?? 'Pendente',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: corTexto,
        ),
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
          // 12 de padding vertical deixa o botão com ~44px de altura,
          // o mínimo recomendado para toque.
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
