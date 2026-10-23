import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Botão largo de ação principal (Entrar, Continuar, Criar conta...).
// Mostra um indicador de progresso no lugar do texto quando [carregando].
class BotaoPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final Color cor;

  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
    this.cor = AppColors.azulPrimario,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: cor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: carregando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              texto,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
