import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ViajaAiApp());
}

class ViajaAiApp extends StatelessWidget {
  const ViajaAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viajaí Bolso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007B6E),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
