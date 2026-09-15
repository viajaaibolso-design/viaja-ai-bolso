import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/viagem_service.dart';
import '../services/currency_service.dart';
import '../utils/moedas.dart';
import 'despesas_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboard;
  Usuario? _perfil;
  bool _loading = true;
  late final String _idUsuario;

  final _currencyService = CurrencyService();
  double? _valorConvertido;
  bool _convertendo = false;
  bool _erroConversao = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    _idUsuario = Supabase.instance.client.auth.currentUser!.id;

    try {
      final perfil = await AuthService().getPerfil(_idUsuario);
      final data = await DashboardService().getDashboard(_idUsuario);
      setState(() {
        _perfil = perfil;
        _dashboard = data;
        _loading = false;
      });
      await _atualizarConversao();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _atualizarConversao() async {
    final viagem = _dashboard?['viagem_ativa'];
    if (viagem == null || _perfil == null) return;
    final moedaLocal = viagem['moeda_local'] as String? ?? 'BRL';
    final moedaConversao = _perfil!.moedaPadrao;
    if (moedaLocal == moedaConversao) {
      setState(() {
        _valorConvertido = null;
        _erroConversao = false;
      });
      return;
    }
    setState(() {
      _convertendo = true;
      _erroConversao = false;
    });
    try {
      final totalGasto = (viagem['total_gasto'] ?? 0).toDouble();
      final convertido = await _currencyService.converter(
          moedaLocal, moedaConversao, totalGasto);
      if (!mounted) return;
      setState(() {
        _valorConvertido = convertido;
        _convertendo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _convertendo = false;
        _erroConversao = true;
      });
    }
  }

  Future<void> _trocarMoedaConversao() async {
    final viagem = _dashboard?['viagem_ativa'];
    final moedaLocal = viagem?['moeda_local'] as String? ?? 'BRL';
    final escolhida = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Converter para qual moeda?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: kMoedas.entries.map((e) {
                  final desabilitada = e.key == moedaLocal;
                  return ListTile(
                    title: Text('${e.key} — ${e.value}'),
                    enabled: !desabilitada,
                    subtitle: desabilitada
                        ? const Text('Igual à moeda local da viagem')
                        : null,
                    trailing: e.key == _perfil?.moedaPadrao
                        ? const Icon(Icons.check, color: kPrimaryColor)
                        : null,
                    onTap: () => Navigator.pop(ctx, e.key),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (escolhida == null || _perfil == null) return;
    final perfilAtual = _perfil!;
    await AuthService().atualizarPerfil(
      _idUsuario,
      perfilAtual.nome,
      perfilAtual.email,
      escolhida,
    );
    setState(() {
      _perfil = Usuario(
        idUsuario: perfilAtual.idUsuario,
        nome: perfilAtual.nome,
        email: perfilAtual.email,
        fotoUrl: perfilAtual.fotoUrl,
        moedaPadrao: escolhida,
        viagemAtivaId: perfilAtual.viagemAtivaId,
      );
    });
    await _atualizarConversao();
  }

  @override
  Widget build(BuildContext context) {
    final viagem = _dashboard?['viagem_ativa'];
    final gastosHoje = _dashboard?['gastos_hoje'];
    final maiorGasto = _dashboard?['maior_gasto'];
    final ultimasDespesas =
        (_dashboard?['ultimas_despesas'] as List?) ?? [];
    final moedaLocal = viagem?['moeda_local'] as String? ?? 'BRL';
    final percentual = (viagem?['percentual_gasto'] ?? 0);
    final estourouOrcamento = percentual is num && percentual > 100;

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
                              Text('Olá, ${_perfil?.nome ?? ''}! 👋',
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
                      if (viagem != null && viagem['id'] != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                estourouOrcamento ? kAlertRust : kPrimaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Resumo da sua viagem',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                  if (estourouOrcamento)
                                    const Text('⚠ orçamento estourado',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                ],
                              ),
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
                                        formatarMoeda(
                                            (viagem['total_gasto'] ?? 0)
                                                .toDouble(),
                                            moedaLocal),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'de ${formatarMoeda((viagem['orcamento'] ?? 0).toDouble(), moedaLocal)}',
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
                              // RF45/RF46 — valor convertido para a moeda
                              // padrão do usuário, com seleção de moeda.
                              if (_perfil != null &&
                                  moedaLocal != _perfil!.moedaPadrao) ...[
                                const SizedBox(height: 14),
                                Container(height: 1, color: Colors.white24),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _trocarMoedaConversao,
                                  child: Row(
                                    children: [
                                      if (_convertendo)
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white70),
                                        )
                                      else if (_erroConversao)
                                        const Text(
                                          'Conversão indisponível no momento',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        )
                                      else if (_valorConvertido != null)
                                        Expanded(
                                          child: Text(
                                            '≈ ${formatarMoeda(_valorConvertido!, _perfil!.moedaPadrao)}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      const Icon(Icons.expand_more,
                                          color: Colors.white70, size: 18),
                                    ],
                                  ),
                                ),
                                if (_currencyService.ultimaAtualizacao(
                                        moedaLocal, _perfil!.moedaPadrao) !=
                                    null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Câmbio atualizado às '
                                      '${_formatarHorario(_currencyService.ultimaAtualizacao(moedaLocal, _perfil!.moedaPadrao)!)}',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 10.5),
                                    ),
                                  ),
                              ],
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
                              valor: formatarMoeda(
                                  (gastosHoje?['total'] ?? 0).toDouble(),
                                  moedaLocal),
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
                              subtitulo: formatarMoeda(
                                  (maiorGasto?['valor'] ?? 0).toDouble(),
                                  moedaLocal),
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
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DespesasScreen())),
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
                        ...ultimasDespesas.map((d) => _ItemDespesa(
                            despesa: d, moedaLocal: moedaLocal)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatarHorario(DateTime data) {
    final h = data.hour.toString().padLeft(2, '0');
    final m = data.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
  final String moedaLocal;

  const _ItemDespesa({required this.despesa, required this.moedaLocal});

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
            formatarMoeda(((despesa['valor'] ?? 0) as num).toDouble(), moedaLocal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
