import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/mensagem_chat.dart';
import '../services/chat_service.dart';
import '../services/viagem_service.dart';

/// Tela do Agente de vIAgens (RF33–RF47) — chat sobre a viagem ativa
/// (orçamento, gastos, dicas de economia) e, desde a v9, um modo de
/// planejamento: o usuário responde uma pequena entrevista e recebe um
/// roteiro com estimativa de custos e sugestões de passagem/hospedagem/
/// restaurante (e dicas de estrada, se for de carro) — tudo estimado
/// pela IA, sem consultar preços reais. Histórico salvo no banco.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<MensagemChat> _mensagens = [];
  String? _conversaId;
  Map<String, dynamic>? _contextoViagem;
  bool _carregando = true;
  bool _enviando = false;
  String? _erroCarregamento;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });
    try {
      final idUsuario = Supabase.instance.client.auth.currentUser!.id;
      final conversaId = await _chatService.obterOuCriarConversa();
      final mensagens = await _chatService.listarMensagens(conversaId);

      // Contexto da viagem ativa é "melhor esforço": se não conseguir
      // montar (ex: usuário sem viagem cadastrada), o chat continua
      // funcionando, só sem esse extra de contexto.
      Map<String, dynamic>? contexto;
      try {
        final dashboard = await DashboardService().getDashboard(idUsuario);
        final viagemAtiva = dashboard['viagem_ativa'];
        if (viagemAtiva != null) {
          contexto = {
            'viagem': viagemAtiva['nome'],
            'destino': viagemAtiva['destino'],
            'moeda_local': viagemAtiva['moeda_local'],
            'orcamento': viagemAtiva['orcamento'],
            'total_gasto': viagemAtiva['total_gasto'],
            'percentual_gasto': viagemAtiva['percentual_gasto'],
            'data_inicio': viagemAtiva['data_inicio'],
            'data_fim': viagemAtiva['data_fim'],
            'gasto_hoje': dashboard['gastos_hoje'],
            'ultimas_despesas': dashboard['ultimas_despesas'],
          };
        }
      } catch (_) {
        contexto = null;
      }

      if (!mounted) return;
      setState(() {
        _conversaId = conversaId;
        _mensagens = mensagens;
        _contextoViagem = contexto;
        _carregando = false;
      });
      _rolarParaFim();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erroCarregamento =
            'Não foi possível carregar o assistente agora. Puxe pra baixo pra tentar de novo.';
      });
    }
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando || _conversaId == null) return;

    final historicoAnterior = List<MensagemChat>.from(_mensagens);
    final mensagemOtimista = MensagemChat(
      conversaId: _conversaId!,
      papel: 'user',
      conteudo: texto,
    );

    setState(() {
      _mensagens = [..._mensagens, mensagemOtimista];
      _enviando = true;
    });
    _controller.clear();
    _rolarParaFim();

    try {
      final resposta = await _chatService.enviarMensagem(
        conversaId: _conversaId!,
        mensagem: texto,
        historico: historicoAnterior,
        contextoViagem: _contextoViagem,
      );
      if (!mounted) return;
      setState(() {
        _mensagens = [..._mensagens, resposta];
        _enviando = false;
      });
      _rolarParaFim();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Remove a mensagem otimista já que a pergunta não foi respondida
        // (ela continua salva no banco, mas evitamos mostrar sem resposta).
        _mensagens = historicoAnterior;
        _enviando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: kAlertRust,
      ));
    }
  }

  /// Envia a entrevista de planejamento (preenchida em _abrirPlanejamento)
  /// e mostra o resultado no chat, do mesmo jeito que uma pergunta comum
  /// — reaproveita o histórico/persistência que já existia para o chat.
  Future<void> _enviarPlanejamento(Map<String, dynamic> entrevista) async {
    if (_conversaId == null || _enviando) return;

    final historicoAnterior = List<MensagemChat>.from(_mensagens);
    final resumo = _chatService.resumirEntrevista(entrevista);
    final mensagemOtimista = MensagemChat(
      conversaId: _conversaId!,
      papel: 'user',
      conteudo: resumo,
    );

    setState(() {
      _mensagens = [..._mensagens, mensagemOtimista];
      _enviando = true;
    });
    _rolarParaFim();

    try {
      final resposta = await _chatService.planejarViagem(
        conversaId: _conversaId!,
        entrevista: entrevista,
      );
      if (!mounted) return;
      setState(() {
        _mensagens = [..._mensagens, resposta];
        _enviando = false;
      });
      _rolarParaFim();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagens = historicoAnterior;
        _enviando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: kAlertRust,
      ));
    }
  }

  DateTime? _parseDataContexto(dynamic valor) {
    if (valor is! String || valor.isEmpty) return null;
    return DateTime.tryParse(valor);
  }

  /// Abre a entrevista de planejamento (painel deslizante): destino,
  /// datas, orçamento, meio de transporte e preferências. Pré-preenche o
  /// que já dá pra aproveitar da viagem ativa, mas tudo é editável.
  Future<void> _abrirPlanejamento() async {
    final destinoCtrl = TextEditingController(
        text: _contextoViagem?['destino']?.toString() ?? '');
    final orcamentoCtrl = TextEditingController(
        text: _contextoViagem?['orcamento'] != null
            ? _contextoViagem!['orcamento'].toString()
            : '');
    final preferenciasCtrl = TextEditingController();
    DateTime? dataInicio = _parseDataContexto(_contextoViagem?['data_inicio']);
    DateTime? dataFim = _parseDataContexto(_contextoViagem?['data_fim']);
    String meioTransporte = 'Avião';
    String? erroDestino;

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          Future<void> escolherData(bool inicio) async {
            final data = await showDatePicker(
              context: ctx,
              initialDate: (inicio ? dataInicio : dataFim) ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx)
                    .copyWith(colorScheme: const ColorScheme.light(primary: kPrimaryColor)),
                child: child!,
              ),
            );
            if (data == null) return;
            setStateModal(() {
              if (inicio) {
                dataInicio = data;
              } else {
                dataFim = data;
              }
            });
          }

          Widget campoData(String rotulo, DateTime? valor, VoidCallback onTap) {
            return GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: kTextGrey),
                    const SizedBox(width: 6),
                    Text(
                      valor == null
                          ? rotulo
                          : '${valor!.day.toString().padLeft(2, '0')}/${valor!.month.toString().padLeft(2, '0')}/${valor!.year}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
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
                  const Text('Planejar viagem com IA',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Responda algumas perguntas e o Agente de vIAgens monta um '
                    'roteiro com estimativa de custos e sugestões de passagem, '
                    'hospedagem e restaurantes (e dicas de estrada, se for de '
                    'carro). Tudo estimado pela IA — confira antes de decidir algo.',
                    style: TextStyle(fontSize: 12.5, color: kTextGrey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: destinoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Destino',
                      hintText: 'Ex.: Gramado, RS',
                      errorText: erroDestino,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: campoData('Data de início', dataInicio,
                            () => escolherData(true)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: campoData(
                            'Data de fim', dataFim, () => escolherData(false)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orcamentoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Orçamento aproximado (opcional)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: meioTransporte,
                    decoration: InputDecoration(
                      labelText: 'Meio de transporte',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Avião', 'Carro', 'Ônibus', 'Outro']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setStateModal(
                        () => meioTransporte = v ?? meioTransporte),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: preferenciasCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Preferências (opcional)',
                      hintText: 'Ex.: praia, aventura, gastronomia, família...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (destinoCtrl.text.trim().isEmpty) {
                          setStateModal(
                              () => erroDestino = 'Informe o destino');
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Gerar roteiro',
                          style: TextStyle(fontSize: 16)),
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

    if (confirmado != true) return;

    String? dataInicioStr;
    String? dataFimStr;
    if (dataInicio != null) {
      dataInicioStr =
          '${dataInicio!.year}-${dataInicio!.month.toString().padLeft(2, '0')}-${dataInicio!.day.toString().padLeft(2, '0')}';
    }
    if (dataFim != null) {
      dataFimStr =
          '${dataFim!.year}-${dataFim!.month.toString().padLeft(2, '0')}-${dataFim!.day.toString().padLeft(2, '0')}';
    }

    final entrevista = <String, dynamic>{
      'destino': destinoCtrl.text.trim(),
      if (dataInicioStr != null) 'dataInicio': dataInicioStr,
      if (dataFimStr != null) 'dataFim': dataFimStr,
      if (orcamentoCtrl.text.trim().isNotEmpty)
        'orcamento': orcamentoCtrl.text.trim(),
      'meioTransporte': meioTransporte,
      if (preferenciasCtrl.text.trim().isNotEmpty)
        'preferencias': preferenciasCtrl.text.trim(),
    };

    await _enviarPlanejamento(entrevista);
  }

  Widget _buildBolha(MensagemChat m) {
    final isUsuario = m.isUsuario;
    return Align(
      alignment: isUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUsuario ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUsuario ? 14 : 2),
            bottomRight: Radius.circular(isUsuario ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          m.conteudo,
          style: TextStyle(
            color: isUsuario ? Colors.white : kTextDark,
            fontSize: 14.5,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBoasVindas() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.smart_toy_outlined, size: 48, color: kPrimaryColor),
          const SizedBox(height: 12),
          const Text(
            'Agente de vIAgens',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pergunte sobre seus gastos, orçamento da viagem ou peça dicas '
            'de economia. Por exemplo: "quanto já gastei hoje?" ou '
            '"como posso economizar mais nessa viagem?" Ou toque em '
            '"Planejar viagem com IA", logo acima, para receber um roteiro '
            'com estimativa de custos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Agente de vIAgens',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _erroCarregamento != null
                ? RefreshIndicator(
                    onRefresh: _iniciar,
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(_erroCarregamento!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kTextGrey)),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: OutlinedButton.icon(
                          onPressed: _enviando ? null : _abrirPlanejamento,
                          icon: const Icon(Icons.route, size: 18),
                          label: const Text('Planejar viagem com IA'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 42),
                            side: const BorderSide(color: kPrimaryColor),
                            foregroundColor: kPrimaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: _mensagens.length +
                              1 + // boas-vindas
                              (_enviando ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == 0) return _buildBoasVindas();
                            final idx = i - 1;
                            if (idx < _mensagens.length) {
                              return _buildBolha(_mensagens[idx]);
                            }
                            // Indicador de "digitando..."
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: kPrimaryColor),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _enviar(),
                                decoration: InputDecoration(
                                  hintText: 'Pergunte ao assistente...',
                                  filled: true,
                                  fillColor: kBackground,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: kPrimaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                onPressed: _enviando ? null : _enviar,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
