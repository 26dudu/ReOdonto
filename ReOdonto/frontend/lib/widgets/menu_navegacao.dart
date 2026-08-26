import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';


enum PaginaApp { perfil, menu, agenda, alertas }

class _ItemMenuInfo {
  final PaginaApp pagina;
  final IconData icone;
  final String texto;
  final String? rota; // null = tela ainda não implementada

  const _ItemMenuInfo({
    required this.pagina,
    required this.icone,
    required this.texto,
    this.rota,
  });
}


const List<_ItemMenuInfo> _itensMenu = [
  _ItemMenuInfo(
    pagina: PaginaApp.perfil,
     icone: Icons.person_outline, 
     texto: 'Perfil',
     rota: '/perfil'),
  _ItemMenuInfo(
    pagina: PaginaApp.menu, 
    icone: Icons.home_outlined,
     texto: 'Menu'),
     // sem rota: telaMenu.dart ainda está vazia
  _ItemMenuInfo(
      pagina: PaginaApp.agenda,
      icone: Icons.calendar_today_outlined,
      texto: 'Agenda',
      rota: '/agenda'),
  _ItemMenuInfo(
      pagina: PaginaApp.alertas,
      icone: Icons.notifications_none_outlined,
      texto: 'Alertas'),
      // sem rota: telaAlertas.dart ainda está vazia
];

/// Navega para a página do item de menu tocado.
/// - Se já estivermos nessa página, não faz nada (evita empilhar a mesma tela).
/// - Se a rota ainda não existir (telas em construção), avisa com um SnackBar.
/// - Caso contrário, troca de tela com pushReplacementNamed — sem empilhar
///   histórico, já que Perfil/Agenda/Menu/Alertas são "abas" do mesmo nível.
void _navegarParaItem(
  BuildContext context,
  _ItemMenuInfo item,
  PaginaApp paginaAtiva,
) {
  if (item.pagina == paginaAtiva) return;

  if (item.rota == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.texto} ainda está em construção.')),
    );
    return;
  }

  Navigator.of(context).pushReplacementNamed(item.rota!);
}


class BotaoMenuSanduiche extends StatelessWidget {
  const BotaoMenuSanduiche({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        onPressed: () => Scaffold.of(context).openDrawer(),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.menu, color: AppColors.textoEscuro),
      ),
    );
  }
}


class BarraLateralMenu extends StatelessWidget {
  final PaginaApp paginaAtiva;
  const BarraLateralMenu({
    super.key, 
    required this.paginaAtiva});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      color: const Color(0xFF1B2733),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _itensMenu.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            InkWell(
              onTap: () =>
                  _navegarParaItem(context, _itensMenu[i], paginaAtiva),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _ItemMenu(
                  icone: _itensMenu[i].icone,
                  texto: _itensMenu[i].texto,
                  ativo: _itensMenu[i].pagina == paginaAtiva,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class MenuSanduiche extends StatelessWidget {
  final PaginaApp paginaAtiva;
  const MenuSanduiche({super.key, required this.paginaAtiva});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1B2733),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD0E2FF),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/tooth-svgrepo-com.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      AppColors.azulPrimario,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            for (final item in _itensMenu)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: InkWell(
                  onTap: () => _navegarParaItem(context, item, paginaAtiva),
                  child: _ItemMenu(
                    icone: item.icone,
                    texto: item.texto,
                    ativo: item.pagina == paginaAtiva,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool ativo;

  const _ItemMenu(
    {required this.icone,
     required this.texto,
      this.ativo = false});

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? AppColors.azulClaro : Colors.white70;
    return Row(
      children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 10),
        Text(
          texto,
          style: TextStyle(
            color: cor,
            fontSize: 13,
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}