import 'package:flutter/material.dart';
import '../../../../../../../theme/app_colors.dart';

// NOVO WIDGET: era o método `_botoesEdicao` dentro da telaPerfil.dart.
// A tela passa só o que muda (salvando / o que fazer ao salvar ou cancelar).

/// Botões "Salvar Alterações" + "Cancelar" do perfil.
/// Empilhados no celular, lado a lado (à direita) no desktop.
class BotoesEdicaoPerfil extends StatelessWidget {
  final bool celular;

  /// true enquanto a API está salvando (mostra spinner e desabilita o botão).
  final bool salvando;
  final VoidCallback onSalvar;
  final VoidCallback onCancelar;

  const BotoesEdicaoPerfil({
    super.key,
    required this.celular,
    required this.salvando,
    required this.onSalvar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    final salvar = ElevatedButton(
      onPressed: salvando ? null : onSalvar,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.azulPrimario,
        minimumSize: const Size(0, 50),
        shape: forma,
      ),
      child: salvando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text('Salvar Alterações',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );

    final cancelar = OutlinedButton(
      onPressed: onCancelar,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: forma),
      child: const Text('Cancelar'),
    );

    return celular
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [salvar, const SizedBox(height: 12), cancelar],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [cancelar, const SizedBox(width: 16), salvar],
          );
  }
}
