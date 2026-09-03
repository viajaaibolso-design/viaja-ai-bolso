import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/viagem_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboard;
  String _nomeUsuario = '';
  bool _loading = true;
  int? _idUsuario;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _idUsuario = prefs.getInt('id_usuario');
    _nomeUsuario = prefs.getString('nome') ?? '';

    try {
      final data = await DashboardService().getDashboard(_idUsuario!);
      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final viagem = _dashboard?['viagem_ativa'];
    final gastosHoje = _dashboard?['gastos_hoje'];
    final maiorGasto = _dashboard?['maior_gasto'];
    final ultimasDespesas =
        (_dashboard?['ultimas_despesas'] as List?) ?? [];

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : RefreshIndicator(
                onRefresh: _carregar,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Olá, $_nomeUsuario! 👋',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const Text('Bom dia para explorar o mundo!',
                                  style: TextStyle(color: kTextGrey)),
                            ],
                          ),
                          const Icon(Icons.notifications_outlined,
                              color: kTextGrey),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card viagem ativa
                      if (viagem != null && viagem['id_viagem'] != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Resumo da sua viagem',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total gasto',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                      Text(
                                        _formatarValor(
                                            (viagem['total_gasto'] ?? 0)
                                                .toDouble()),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'de ${_formatarValor((viagem['orcamento'] ?? 0).toDouble())}',
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: CircularProgressIndicator(
                                          value: ((viagem['percentual_gasto'] ??
                                                      0) /
                                                  100)
                                              .clamp(0.0, 1.0),
                                          backgroundColor:
                                              Colors.white24,
                                          color: Colors.white,
                                          strokeWidth: 6,
                                        ),
                                      ),
                                      Text(
                                        '${viagem['percentual_gasto'] ?? 0}%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Nenhuma viagem ativa.\nCrie uma viagem para começar!',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Gastos hoje e maior gasto
                      Row(
                        children: [
                          Expanded(
                            child: _CardInfo(
                              titulo: 'Gastos de hoje',
                              valor: _formatarValor(
                                  (gastosHoje?['total'] ?? 0).toDouble()),
                              subtitulo:
                                  '${gastosHoje?['quantidade'] ?? 0} despesas',
                              icone: Icons.today,
                              cor: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CardInfo(
                              titulo: 'Maior gasto',
                              valor: maiorGasto?['categoria'] ?? 'N/A',
                              subtitulo: _formatarValor(
                                  (maiorGasto?['valor'] ?? 0).toDouble()),
                              icone: Icons.trending_up,
                              cor: Colors.orange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Últimas despesas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Últimas despesas',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Ver todas',
                                style: TextStyle(color: kPrimaryColor)),
                          ),
                        ],
                      ),

                      if (ultimasDespesas.isEmpty)
                        const Center(
                            child: Text('Nenhuma despesa registrada',
                                style: TextStyle(color: kTextGrey)))
                      else
                        ...ultimasDespesas.map((d) => _ItemDespesa(despesa: d)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;
  final Color cor;

  const _CardInfo({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(height: 8),
          Text(titulo,
              style: const TextStyle(color: kTextGrey, fontSize: 12)),
          Text(valor,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          Text(subtitulo,
              style: const TextStyle(color: kTextGrey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ItemDespesa extends StatelessWidget {
  final Map<String, dynamic> despesa;

  const _ItemDespesa({required this.despesa});

  IconData _iconeCategoria(String? icone) {
    switch (icone) {
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'attractions': return Icons.attractions;
      case 'card_giftcard': return Icons.card_giftcard;
      default: return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
            child: Icon(_iconeCategoria(despesa['icone']),
                color: kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(despesa['descricao'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${despesa['categoria'] ?? ''} · ${despesa['hora'] ?? despesa['data'] ?? ''}',
                  style: const TextStyle(color: kTextGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${((despesa['valor'] ?? 0) as num).toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
