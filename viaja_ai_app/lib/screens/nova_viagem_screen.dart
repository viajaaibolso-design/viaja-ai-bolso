import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../models/viagem.dart';
import '../services/viagem_service.dart';

class NovaViagemScreen extends StatefulWidget {
  final Viagem? viagem;
  const NovaViagemScreen({super.key, this.viagem});

  @override
  State<NovaViagemScreen> createState() => _NovaViagemScreenState();
}

class _NovaViagemScreenState extends State<NovaViagemScreen> {
  final _nomeCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();
  final _orcamentoCtrl = TextEditingController();
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _loading = false;
  String? _imagemBase64;
  Uint8List? _imagemBytes;
  bool get _editando => widget.viagem != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      _nomeCtrl.text = widget.viagem!.nome;
      _destinoCtrl.text = widget.viagem!.destino;
      _orcamentoCtrl.text = widget.viagem!.orcamento.toStringAsFixed(2);
      _dataInicio = DateTime.tryParse(widget.viagem!.dataInicio);
      _dataFim = DateTime.tryParse(widget.viagem!.dataFim);
      // Carrega foto existente
      if (widget.viagem!.foto != null && widget.viagem!.foto!.isNotEmpty) {
        try {
          _imagemBytes = base64Decode(widget.viagem!.foto!);
          _imagemBase64 = widget.viagem!.foto;
        } catch (_) {}
      }
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _selecionarImagem() async {
    try {
      final picker = ImagePicker();
      // Usa gallery — funciona em web, Android e iOS
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Str = base64Encode(bytes);
        setState(() {
          _imagemBytes = bytes;
          _imagemBase64 = base64Str;
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao selecionar imagem');
    }
  }

  Future<void> _selecionarData(bool isInicio) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimaryColor),
        ),
        child: child!,
      ),
    );
    if (data != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = data;
        } else {
          _dataFim = data;
        }
      });
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Selecionar data';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _toIso(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty ||
        _destinoCtrl.text.trim().isEmpty ||
        _dataInicio == null ||
        _dataFim == null) {
      _mostrarErro('Preencha todos os campos obrigatórios');
      return;
    }
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getInt('id_usuario');

    try {
      if (_editando) {
        await ViagemService().atualizar({
          'id_viagem': widget.viagem!.idViagem,
          'nome': _nomeCtrl.text.trim(),
          'destino': _destinoCtrl.text.trim(),
          'foto': _imagemBase64,
          'data_inicio': _toIso(_dataInicio!),
          'data_fim': _toIso(_dataFim!),
          'orcamento': double.tryParse(_orcamentoCtrl.text) ?? 0,
        });
      } else {
        await ViagemService().cadastrar({
          'nome': _nomeCtrl.text.trim(),
          'destino': _destinoCtrl.text.trim(),
          'foto': _imagemBase64,
          'data_inicio': _toIso(_dataInicio!),
          'data_fim': _toIso(_dataFim!),
          'orcamento': double.tryParse(_orcamentoCtrl.text) ?? 0,
          'id_usuario': idUsuario,
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _mostrarErro('Erro ao salvar viagem');
    }
    setState(() => _loading = false);
  }

  Widget _buildFoto() {
    if (_imagemBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _imagemBytes!,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, color: kTextGrey, size: 32),
          SizedBox(height: 4),
          Text(
            'Adicionar foto\ndo destino',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextDark,
        title: Text(_editando ? 'Editar viagem' : 'Nova viagem',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nova viagem',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Informe os dados da sua viagem',
                style: TextStyle(color: kTextGrey)),
            const SizedBox(height: 24),

            // Seletor de foto
            Center(
              child: GestureDetector(
                onTap: _selecionarImagem,
                child: Stack(
                  children: [
                    _buildFoto(),
                    if (_imagemBytes != null)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_imagemBytes != null)
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() {
                        _imagemBytes = null;
                        _imagemBase64 = null;
                      }),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  label: const Text('Remover foto',
                      style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ),
            const SizedBox(height: 20),

            TextField(
              controller: _nomeCtrl,
              decoration: InputDecoration(
                labelText: 'Nome da viagem',
                hintText: 'Ex.: Férias em Paris',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _destinoCtrl,
              decoration: InputDecoration(
                labelText: 'Destino',
                hintText: 'Ex.: Paris, França',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selecionarData(true),
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
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Data de início',
                                  style: TextStyle(
                                      color: kTextGrey, fontSize: 11)),
                              Text(_formatarData(_dataInicio),
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selecionarData(false),
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
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Data de fim',
                                  style: TextStyle(
                                      color: kTextGrey, fontSize: 11)),
                              Text(_formatarData(_dataFim),
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _orcamentoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Orçamento previsto (opcional)',
                hintText: 'R\$ 5.000,00',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar viagem',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
