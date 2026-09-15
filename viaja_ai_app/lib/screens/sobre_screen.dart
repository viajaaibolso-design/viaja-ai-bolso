import 'package:flutter/material.dart';
import '../constants.dart';
import 'termos_screen.dart';

/// RF31 — Tela "Sobre o app".
class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Sobre o app',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flight_takeoff,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 14),
                const Text('ViajAí Bolso',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor)),
                const SizedBox(height: 4),
                const Text('Versão 1.0.0',
                    style: TextStyle(color: kTextGrey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'O ViajAí Bolso é um aplicativo para controle e gestão visual de gastos '
            'em viagens: cadastre suas viagens, registre despesas por categoria e '
            'acompanhe o quanto já foi gasto em relação ao orçamento planejado.',
            style: TextStyle(fontSize: 14, height: 1.6, color: kTextDark),
          ),
          const SizedBox(height: 20),
          const Text(
            'O projeto nasceu como protótipo de conclusão do 3º período do curso de '
            'Análise e Desenvolvimento de Sistemas e está em evolução para se tornar '
            'o Trabalho de Conclusão de Curso (TCC), com novas funcionalidades como '
            'assistente de viagem com IA, leitura automática de notas fiscais e '
            'conversão de câmbio.',
            style: TextStyle(fontSize: 14, height: 1.6, color: kTextDark),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: kPrimaryColor),
              title: const Text('Termos de Uso e Privacidade'),
              trailing: const Icon(Icons.chevron_right, color: kTextGrey),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TermosScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
