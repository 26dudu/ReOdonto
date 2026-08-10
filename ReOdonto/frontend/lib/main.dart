import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import './pages/telaLogin.dart';

void main() {
  runApp(DevicePreview(builder: (context) => MeuApp()));
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReOdonto',
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,

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
