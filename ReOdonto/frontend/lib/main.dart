import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:reodonto/pages/telaPerfil.dart';
import 'package:reodonto/pages/telaAgenda.dart';
import './pages/telaLogin.dart';
import './services/sessao_usuario.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool temSessao = await SessaoUsuario.carregar();

  if (kDebugMode) {
    runApp(DevicePreview(builder: (context) => MeuApp(temSessao: temSessao)));
  } else {
    runApp(MeuApp(temSessao: temSessao));
  }
}

class MeuApp extends StatelessWidget {
  final bool temSessao;
  const MeuApp({super.key, required this.temSessao});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReOdonto',
      debugShowCheckedModeBanner: false,
      builder: kDebugMode ? DevicePreview.appBuilder : null,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 243, 248, 255),
          secondary: const Color.fromARGB(255, 30, 95, 216),
        ),
      ),
      home: temSessao ? const TelaPerfil() : const TelaLogin(),

      // Rotas nomeadas usadas pelo menu (BarraLateralMenu / MenuSanduiche)
      // para trocar de tela. Adicione aqui conforme telaMenu.dart e telaAlertas.dart forem implementadas.
      routes: {
        '/perfil': (context) => const TelaPerfil(),
        '/agenda': (context) => const TelaAgenda(),
      },
    );
  }
}