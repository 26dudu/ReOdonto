import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Português do Brasil nos widgets nativos (calendário, botões, meses...).
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:device_preview/device_preview.dart';
import 'package:reodonto/pages/telaPerfil.dart';
import 'package:reodonto/pages/telaAgenda.dart';
import 'package:reodonto/pages/telaMenu.dart';
import 'package:reodonto/pages/telaAlertas.dart';
import './pages/telaLogin.dart';
import './services/sessao_usuario.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

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

      // Idioma do app: o showDatePicker (SeletorDia) e demais widgets saem em português.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

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
      //home:  const TelaPerfil(),
      //home: TelaNovaSenha(email: 'teste@teste.com'),
      //home: const TelaLogin(),

      // Rotas usadas pelo menu de navegação (widgets/menu_navegacao.dart).
      routes: {
        '/perfil': (context) => const TelaPerfil(),
        '/agenda': (context) => const TelaAgenda(),
        '/menu': (context) => const TelaMenu(),
        '/alertas': (context) => const TelaAlertas(),
      },
    );
  }
}
