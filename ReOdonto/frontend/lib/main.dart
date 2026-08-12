import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import './pages/telaLogin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    runApp(DevicePreview(builder: (context) => const MeuApp()));
  } else {
    runApp(const MeuApp());
  }
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

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
      home: const TelaLogin(),
    );
  }
}
