import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/despesa.dart';
import '../models/viagem.dart';
import '../services/viagem_service.dart';

class DespesasScreen extends StatefulWidget {
  const DespesasScreen({super.key});

  @override
  State<DespesasScreen> createState() => _DespesasScreenState();
}

class _DespesasScreenState extends State<DespesasScreen> {
  List<Viagem> _viagens = [];
  List<Despesa> _despesas = [];
  List<Categoria> _categorias = [];
  Viagem? _viagemSelecionada;
  String _filtroCategoria = 'Todas';
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
    try {
      final viagens = await ViagemService().listar(_idUsuario!);
      final categorias = await DespesaService().listarCategorias();
      setState(() {
        _viagens = viagens;
        _categorias = categorias;
        if (_viagemSelecionada == null && viagens.isNotEmpty) {
          _viagemSelecionada = viagens.first;
        }
        _loading = false;
      });
      if (_viagemSelecionada != null) {
        await _carregarDespesas();
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _carregarDespesas() async {
    if (_viagemSelecionada == null) return;
    try {
      final despesas =
          await DespesaService().listar(_viagemSelecionada!.idViagem!);
      setState(() => _despesas = despesas);
    } catch (_) {}
  }

  List<Despesa> get _despesasFiltradas {
    if (_filtroCategoria == 'Todas') return _despesas;
    return _despesas.where((d) => d.categoria == _filtroCategoria).toList();
  }

  double get _totalFiltrado =>
      _despesasFiltradas.fold(0, (soma, d) => soma + d.valor);

  IconData _iconeCategoria(String? icone) {
    switch (icone) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'attractions':
        return Icons.attractions;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.more_horiz;
    }
  }

  Future<void> _abrirFormulario({Despesa? despesa}) async {
    final descricaoCtrl = TextEditingController(text: despesa?.descricao ?? '');
    final valorCtrl =
        TextEditingController(text: despesa?.valor.toStringAsFixed(2) ?? '');
    Categoria? categoriaSelecionada = despesa != null
        ? _categorias.firstWhere((c) => c.idCategoria == despesa.idCategoria,
            orElse: () => _categorias.first)
        : (_categorias.isNotEmpty ? _categorias.first : null);
    String formaPagamento = despesa?.formaPagamento ?? 'Cartão de crédito';
    DateTime dataSelecionada = despesa?.data != null
        ? DateTime.tryParse(despesa!.data) ?? DateTime.now()
        : DateTime.now();

    final formas = [
      'Cartão de crédito',
      'Cartão de débito',
      'Dinheiro',
      'Pix',
      'Outros'
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  despesa != null ? 'Editar despesa' : 'Nova despesa',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Seletor de categoria
                const Text('Categoria',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categorias.map((c) {
                      final selecionada =
                          categoriaSelecionada?.idCategoria == c.idCategoria;
                      return GestureDetector(
                        onTap: () =>
                            setStateModal(() => categoriaSelecionada = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selecionada ? kPrimaryColor : kBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Icon(_iconeCategoria(c.icone),
                                  color: selecionada ? Colors.white : kTextGrey,
                                  size: 22),
                              Text(c.nome,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: selecionada
                                          ? Colors.white
                                          : kTextGrey)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descricaoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Almoço em restaurante',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: valorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Valor (R\$)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final data = await showDatePicker(
                            context: ctx,
                            initialDate: dataSelecionada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(
                                    primary: kPrimaryColor),
                              ),
                              child: child!,
                            ),
                          );
                          if (data != null) {
                            setStateModal(() => dataSelecionada = data);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: kTextGrey),
                              const SizedBox(width: 6),
                              Text(
                                '${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: formaPagamento,
                  decoration: InputDecoration(
                    labelText: 'Forma de pagamento',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: formas
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) =>
                      setStateModal(() => formaPagamento = v ?? formas.first),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (descricaoCtrl.text.trim().isEmpty ||
                          valorCtrl.text.trim().isEmpty ||
                          categoriaSelecionada == null) {
                        return;
                      }
                      Navigator.pop(ctx);
                      final dataStr =
                          '${dataSelecionada.year}-${dataSelecionada.month.toString().padLeft(2, '0')}-${dataSelecionada.day.toString().padLeft(2, '0')}';

                      if (despesa != null) {
                        await DespesaService().atualizar({
                          'id_despesa': despesa.idDespesa,
                          'descricao': descricaoCtrl.text.trim(),
                          'valor': double.tryParse(valorCtrl.text) ?? 0,
                          'data': dataStr,
                          'forma_pagamento': formaPagamento,
                          'id_categoria': categoriaSelecionada!.idCategoria,
                        });
                      } else {
                        await DespesaService().cadastrar({
                          'descricao': descricaoCtrl.text.trim(),
                          'valor': double.tryParse(valorCtrl.text) ?? 0,
                          'data': dataStr,
                          'forma_pagamento': formaPagamento,
                          'id_viagem': _viagemSelecionada!.idViagem,
                          'id_categoria': categoriaSelecionada!.idCategoria,
                        });
                      }
                      _carregarDespesas();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(despesa != null ? 'Salvar' : 'Salvar despesa',
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarRemocao(Despesa despesa) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Despesa'),
        content: Text('Deseja remover "${despesa.descricao}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await DespesaService().remover(despesa.idDespesa!);
      _carregarDespesas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtros = ['Todas', ..._categorias.map((c) => c.nome)];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Minhas despesas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_alt_outlined), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Column(
              children: [
                // Seletor de viagem
                if (_viagens.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<Viagem>(
                      initialValue: _viagemSelecionada,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: _viagens
                          .map((v) =>
                              DropdownMenuItem(value: v, child: Text(v.nome)))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _viagemSelecionada = v);
                        _carregarDespesas();
                      },
                    ),
                  ),

                // Filtros de categoria
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filtros.map((f) {
                        final selecionado = _filtroCategoria == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filtroCategoria = f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selecionado ? kPrimaryColor : kBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                    color:
                                        selecionado ? Colors.white : kTextGrey,
                                    fontSize: 13)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Lista de despesas
                Expanded(
                  child: _despesasFiltradas.isEmpty
                      ? const Center(
                          child: Text('Nenhuma despesa registrada',
                              style: TextStyle(color: kTextGrey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _despesasFiltradas.length,
                          itemBuilder: (ctx, i) {
                            final d = _despesasFiltradas[i];
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
                                    backgroundColor:
                                        kPrimaryColor.withValues(alpha: 0.1),
                                    child: Icon(_iconeCategoria(d.icone),
                                        color: kPrimaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(d.descricao,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        Text(
                                          '${d.categoria} · ${d.hora ?? d.data}',
                                          style: const TextStyle(
                                              color: kTextGrey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'R\$ ${d.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 16, color: kPrimaryColor),
                                            onPressed: () =>
                                                _abrirFormulario(despesa: d),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 16, color: Colors.red),
                                            onPressed: () =>
                                                _confirmarRemocao(d),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: kPrimaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(
                        'R\$ ${_totalFiltrado.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _viagemSelecionada != null
          ? FloatingActionButton(
              onPressed: () => _abrirFormulario(),
              backgroundColor: kPrimaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
