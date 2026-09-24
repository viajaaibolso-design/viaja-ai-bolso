import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../models/despesa.dart';
import '../models/viagem.dart';
import '../services/viagem_service.dart';
import '../services/storage_service.dart';
import '../services/nota_fiscal_service.dart';
import '../models/resultado_extracao.dart';
import '../utils/moedas.dart';
import '../utils/exportacao.dart';

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
  bool _exportando = false;
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
      final viagens = await ViagemService().listar(_idUsuario);
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

  String get _moedaAtual => _viagemSelecionada?.moedaLocal ?? 'BRL';

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

  Future<void> _exportar() async {
    if (_despesasFiltradas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não há despesas para exportar'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _exportando = true);
    try {
      final csv = gerarCsvDespesas(_despesasFiltradas, _moedaAtual);
      final bytes = Uint8List.fromList(csv.codeUnits);
      final nomeViagem =
          (_viagemSelecionada?.nome ?? 'viagem').replaceAll(RegExp(r'\s+'), '_');
      final caminho =
          '$_idUsuario/exportacoes/despesas_${nomeViagem}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final url = await StorageService()
          .upload(caminho, bytes, contentType: 'text/csv');
      setState(() => _exportando = false);
      if (mounted) _mostrarLinkExportacao(url);
    } catch (_) {
      setState(() => _exportando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao gerar exportação'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _mostrarLinkExportacao(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportação pronta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Copie o link abaixo e abra no navegador para baixar a planilha (CSV) das despesas filtradas — pronta para prestação de contas.'),
            const SizedBox(height: 12),
            SelectableText(url,
                style: const TextStyle(fontSize: 12, color: kPrimaryColor)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Link copiado!'),
                  backgroundColor: Colors.green));
            },
            child: const Text('Copiar link',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _verComprovante(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url,
              errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Não foi possível carregar o comprovante'),
                  )),
        ),
      ),
    );
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

    // RF22 — comprovante anexado à despesa.
    String? comprovanteUrlExistente = despesa?.fotoUrl;
    Uint8List? comprovanteBytes;
    bool comprovanteAlterado = false;

    // RF48–RF51 — leitura automática de nota fiscal por visão
    // computacional. Só faz sentido numa despesa nova (não ao editar).
    String modoEntrada = despesa == null ? 'escanear' : 'manual';
    bool extraindo = false;
    String? avisoExtracao;
    Color corAvisoExtracao = kPrimaryLight;

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
        builder: (ctx, setStateModal) {
          Future<void> escanear(ImageSource fonte) async {
            final picker = ImagePicker();
            final arquivo = await picker.pickImage(
              source: fonte,
              maxWidth: 1000,
              maxHeight: 1000,
              imageQuality: 70,
            );
            if (arquivo == null) return;
            final bytes = await arquivo.readAsBytes();
            setStateModal(() {
              extraindo = true;
              avisoExtracao = null;
            });
            final resultado = await NotaFiscalService().extrair(bytes);
            setStateModal(() {
              extraindo = false;
              comprovanteBytes = bytes;
              comprovanteAlterado = true;
              if (resultado.sucesso) {
                if (resultado.estabelecimento != null &&
                    resultado.estabelecimento!.isNotEmpty) {
                  descricaoCtrl.text = resultado.estabelecimento!;
                }
                if (resultado.valor != null) {
                  valorCtrl.text = resultado.valor!.toStringAsFixed(2);
                }
                if (resultado.data != null) {
                  final data = DateTime.tryParse(resultado.data!);
                  if (data != null) dataSelecionada = data;
                }
                if (resultado.categoria != null) {
                  final match = _categorias
                      .where((c) =>
                          c.nome.toLowerCase() ==
                          resultado.categoria!.toLowerCase())
                      .toList();
                  if (match.isNotEmpty) categoriaSelecionada = match.first;
                }
                avisoExtracao =
                    'Dados reconhecidos automaticamente. Confira antes de salvar.';
                corAvisoExtracao = kPrimaryLight;
              } else {
                avisoExtracao = resultado.erro ??
                    'Não conseguimos ler os dados da nota. Preencha manualmente.';
                corAvisoExtracao = kAlertRust;
              }
            });
          }

          return Padding(
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

                if (despesa == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateModal(() => modoEntrada = 'escanear'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: modoEntrada == 'escanear'
                                  ? kPrimaryColor
                                  : kBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: modoEntrada == 'escanear'
                                      ? kPrimaryColor
                                      : Colors.grey[300]!),
                            ),
                            child: Text('📷 Escanear nota',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: modoEntrada == 'escanear'
                                        ? Colors.white
                                        : kTextGrey)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateModal(() => modoEntrada = 'manual'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: modoEntrada == 'manual'
                                  ? kPrimaryColor
                                  : kBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: modoEntrada == 'manual'
                                      ? kPrimaryColor
                                      : Colors.grey[300]!),
                            ),
                            child: Text('✍️ Digitar manualmente',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: modoEntrada == 'manual'
                                        ? Colors.white
                                        : kTextGrey)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (modoEntrada == 'escanear') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 22, horizontal: 16),
                      decoration: BoxDecoration(
                        color: kPrimaryLight.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: kPrimaryLight.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long,
                              size: 30, color: kPrimaryLight),
                          const SizedBox(height: 8),
                          const Text('Aponte a câmera para a nota fiscal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          const Text('ou selecione uma imagem da galeria',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 11.5, color: kTextGrey)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: extraindo
                                      ? null
                                      : () => escanear(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt, size: 16),
                                  label: const Text('Câmera'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: extraindo
                                      ? null
                                      : () => escanear(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library,
                                      size: 16),
                                  label: const Text('Galeria'),
                                ),
                              ),
                            ],
                          ),
                          if (extraindo) ...[
                            const SizedBox(height: 12),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: kPrimaryColor)),
                                SizedBox(width: 8),
                                Text('Analisando nota fiscal...',
                                    style: TextStyle(
                                        fontSize: 12, color: kTextGrey)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (avisoExtracao != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: corAvisoExtracao.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(avisoExtracao!,
                          style:
                              TextStyle(fontSize: 12, color: corAvisoExtracao)),
                    ),
                ],

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
                          labelText: 'Valor ($_moedaAtual)',
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
                const SizedBox(height: 14),

                // Comprovante (RF22)
                const Text('Comprovante (opcional)',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (comprovanteBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(comprovanteBytes!,
                            width: 56, height: 56, fit: BoxFit.cover),
                      )
                    else if (!comprovanteAlterado &&
                        comprovanteUrlExistente != null &&
                        comprovanteUrlExistente!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(comprovanteUrlExistente!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: kBackground,
                                child: const Icon(Icons.receipt_long,
                                    color: kTextGrey))),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: kBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long,
                            color: kTextGrey),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final arquivo = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1000,
                                maxHeight: 1000,
                                imageQuality: 70,
                              );
                              if (arquivo != null) {
                                final bytes = await arquivo.readAsBytes();
                                setStateModal(() {
                                  comprovanteBytes = bytes;
                                  comprovanteAlterado = true;
                                });
                              }
                            },
                            icon: const Icon(Icons.attach_file, size: 16),
                            label: Text(
                                comprovanteBytes != null ||
                                        (!comprovanteAlterado &&
                                            comprovanteUrlExistente != null &&
                                            comprovanteUrlExistente!
                                                .isNotEmpty)
                                    ? 'Trocar'
                                    : 'Anexar'),
                          ),
                          if (comprovanteBytes != null ||
                              (!comprovanteAlterado &&
                                  comprovanteUrlExistente != null &&
                                  comprovanteUrlExistente!.isNotEmpty))
                            TextButton.icon(
                              onPressed: () => setStateModal(() {
                                comprovanteBytes = null;
                                comprovanteUrlExistente = null;
                                comprovanteAlterado = true;
                              }),
                              icon: const Icon(Icons.delete,
                                  size: 16, color: Colors.red),
                              label: const Text('Remover',
                                  style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
                  ],
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

                      String? fotoUrl = comprovanteUrlExistente;
                      if (comprovanteAlterado) {
                        if (comprovanteBytes != null) {
                          final caminho =
                              '$_idUsuario/despesas/${DateTime.now().millisecondsSinceEpoch}.jpg';
                          fotoUrl = await StorageService()
                              .upload(caminho, comprovanteBytes!);
                        } else {
                          fotoUrl = null;
                        }
                      }

                      if (despesa != null) {
                        await DespesaService().atualizar({
                          'id_despesa': despesa.idDespesa,
                          'descricao': descricaoCtrl.text.trim(),
                          'valor': double.tryParse(valorCtrl.text) ?? 0,
                          'data': dataStr,
                          'forma_pagamento': formaPagamento,
                          'categoria_id': categoriaSelecionada!.idCategoria,
                          'foto_url': fotoUrl,
                        });
                      } else {
                        await DespesaService().cadastrar({
                          'descricao': descricaoCtrl.text.trim(),
                          'valor': double.tryParse(valorCtrl.text) ?? 0,
                          'data': dataStr,
                          'forma_pagamento': formaPagamento,
                          'viagem_id': _viagemSelecionada!.idViagem,
                          'categoria_id': categoriaSelecionada!.idCategoria,
                          'foto_url': fotoUrl,
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
        );
        },
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
            icon: _exportando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kPrimaryColor))
                : const Icon(Icons.ios_share),
            tooltip: 'Exportar despesas (CSV)',
            onPressed: _exportando ? null : _exportar,
          ),
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
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(d.descricao,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ),
                                            if (d.fotoUrl != null &&
                                                d.fotoUrl!.isNotEmpty)
                                              GestureDetector(
                                                onTap: () =>
                                                    _verComprovante(d.fotoUrl!),
                                                child: const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 6),
                                                  child: Icon(
                                                      Icons.attach_file,
                                                      size: 14,
                                                      color: kPrimaryColor),
                                                ),
                                              ),
                                          ],
                                        ),
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
                                        formatarMoeda(d.valor, _moedaAtual),
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
                        formatarMoeda(_totalFiltrado, _moedaAtual),
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
