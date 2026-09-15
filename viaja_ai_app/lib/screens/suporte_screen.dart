import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';

/// RF32 — Canal de suporte dentro do app. Mantido simples (sem pacote
/// novo para abrir e-mail/app externo): mostra o contato e um pequeno
/// FAQ, com opção de copiar o e-mail de suporte.
class SuporteScreen extends StatelessWidget {
  const SuporteScreen({super.key});

  static const _emailSuporte = 'viajaaibolso@gmail.com';

  void _copiarEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _emailSuporte));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('E-mail copiado!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final faq = [
      (
        'Esqueci minha senha, e agora?',
        'Na tela de login, toque em "Esqueci minha senha" e siga o código '
            'enviado para o seu e-mail cadastrado.',
      ),
      (
        'Os valores convertidos na tela inicial são exatos?',
        'Não — são estimativas com base em uma taxa de câmbio atualizada '
            'periodicamente, úteis para referência, mas podem variar em '
            'relação ao câmbio real no momento da sua viagem.',
      ),
      (
        'Posso usar o app sem internet?',
        'É possível consultar viagens e despesas já carregadas '
            'anteriormente, mas cadastrar ou editar dados exige conexão, '
            'pois tudo é salvo diretamente no servidor.',
      ),
    ];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title:
            const Text('Suporte', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fale com a gente',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(_emailSuporte,
                          style:
                              const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copiarEmail(context),
                  icon: const Icon(Icons.copy, color: Colors.white),
                  tooltip: 'Copiar e-mail',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Perguntas frequentes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...faq.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(item.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2,
                        style: const TextStyle(
                            color: kTextGrey, fontSize: 13, height: 1.5)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
