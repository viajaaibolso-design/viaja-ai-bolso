import 'package:flutter/material.dart';
import '../constants.dart';
import 'termos_screen.dart';

/// RF30 — Tela de configurações gerais do app. Mantida enxuta: o que já
/// tem tela própria (moeda padrão, no Perfil) não é duplicado aqui.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  // Preferência local de notificações. Ainda não há notificações push
  // implementadas no app — este switch fica pronto para quando houver.
  bool _notificacoes = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Configurações',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificacoes,
                  activeThumbColor: kPrimaryColor,
                  title: const Text('Notificações'),
                  subtitle: const Text('Avisos sobre orçamento e viagens',
                      style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setState(() => _notificacoes = v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: kPrimaryColor),
                  title: const Text('Termos de Uso e Privacidade'),
                  trailing:
                      const Icon(Icons.chevron_right, color: kTextGrey),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TermosScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
