import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/viagem.dart';
import '../services/viagem_service.dart';
import 'nova_viagem_screen.dart';

class ViagensScreen extends StatefulWidget {
  const ViagensScreen({super.key});

  @override
  State<ViagensScreen> createState() => _ViagensScreenState();
}

class _ViagensScreenState extends State<ViagensScreen> {
  List<Viagem> _viagens = [];
  bool _loading = true;
  late final String _idUsuario;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    _idUsuario = Supabase.instance.client.auth.currentUser!.id;
    try {
      final lista = await ViagemService().listar(_idUsuario);
      setState(() {
        _viagens = lista;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmarRemocao(Viagem viagem) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Viagem'),
        content: Text(
            'Deseja remover "${viagem.nome}"? Todas as despesas serão removidas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await ViagemService().remover(viagem.idViagem!);
      _carregar();
    }
  }

  String _formatarValor(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  Widget _buildFotoViagem(Viagem v) {
    if (v.fotoUrl != null && v.fotoUrl!.isNotEmpty) {
      return Image.network(
        v.fotoUrl!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderFoto(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(
                color: kPrimaryColor,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }
    return _placeholderFoto();
  }

  Widget _placeholderFoto() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.15),
      ),
      child: const Center(
        child: Icon(Icons.flight_takeoff, size: 52, color: kPrimaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Minhas viagens',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor))
          : _viagens.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.luggage, size: 60, color: kTextGrey),
                      SizedBox(height: 12),
                      Text('Nenhuma viagem cadastrada',
                          style: TextStyle(color: kTextGrey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _viagens.length,
                    itemBuilder: (ctx, i) {
                      final v = _viagens[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: _buildFotoViagem(v),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(v.nome,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: kPrimaryColor,
                                                size: 20),
                                            onPressed: () async {
                                              await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          NovaViagemScreen(
                                                              viagem: v)));
                                              _carregar();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red, size: 20),
                                            onPressed: () =>
                                                _confirmarRemocao(v),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(v.destino,
                                      style:
                                          const TextStyle(color: kTextGrey)),
                                  Text('${v.dataInicio} · ${v.dataFim}',
                                      style: const TextStyle(
                                          color: kTextGrey, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gasto total: ${_formatarValor(v.totalGasto)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: (v.percentualGasto / 100)
                                        .clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey[200],
                                    color: kPrimaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  Text(
                                      '${v.percentualGasto}% do orçamento',
                                      style: const TextStyle(
                                          color: kTextGrey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NovaViagemScreen()));
          _carregar();
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
