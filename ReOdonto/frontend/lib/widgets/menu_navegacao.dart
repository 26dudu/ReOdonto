import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../utils/avisos.dart';

enum PaginaApp { perfil, menu, agenda, alertas }

class _ItemMenuInfo {
  final PaginaApp pagina;
  final IconData icone;
  final String texto;
  final String? rota;

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
    rota: '/perfil',
  ),
  _ItemMenuInfo(
    pagina: PaginaApp.menu,
    icone: Icons.home_outlined,
    texto: 'Menu',
    rota: '/menu',
  ),

  _ItemMenuInfo(
    pagina: PaginaApp.agenda,
    icone: Icons.calendar_today_outlined,
    texto: 'Agenda',
    rota: '/agenda',
  ),
  _ItemMenuInfo(
    pagina: PaginaApp.alertas,
    icone: Icons.notifications_none_outlined,
    texto: 'Alertas',
    rota: '/alertas',
  ),
];

void _navegarParaItem(
  BuildContext context,
  _ItemMenuInfo item,
  PaginaApp paginaAtiva,
) {
  if (item.pagina == paginaAtiva) return;

  if (item.rota == null) {
    mostrarAviso(context, '${item.texto} ainda está em construção.');
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
  const BarraLateralMenu({super.key, required this.paginaAtiva});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      color: const Color(0xFF1B2733),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int posicao = 0; posicao < _itensMenu.length; posicao++) ...[
            if (posicao > 0) const SizedBox(height: 18),
            InkWell(
              onTap: () =>
                  _navegarParaItem(context, _itensMenu[posicao], paginaAtiva),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _ItemMenu(
                  icone: _itensMenu[posicao].icone,
                  texto: _itensMenu[posicao].texto,
                  ativo: _itensMenu[posicao].pagina == paginaAtiva,
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
                  border: Border.all(color: const Color(0xFFD0E2FF), width: 2),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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

  const _ItemMenu({
    required this.icone,
    required this.texto,
    this.ativo = false,
  });

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
