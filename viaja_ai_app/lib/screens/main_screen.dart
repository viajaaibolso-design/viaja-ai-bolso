import 'package:flutter/material.dart';
import '../constants.dart';
import 'dashboard_screen.dart';
import 'viagens_screen.dart';
import 'despesas_screen.dart';
import 'chat_screen.dart';
import 'perfil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indiceAtual = 0;

  final List<Widget> _telas = [
    const DashboardScreen(),
    const ViagensScreen(),
    const DespesasScreen(),
    const ChatScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (i) => setState(() => _indiceAtual = i),
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: kTextGrey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.luggage), label: 'Viagens'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Despesas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined), label: 'Agente'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
