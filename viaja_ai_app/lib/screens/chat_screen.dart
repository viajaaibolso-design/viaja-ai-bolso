import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/mensagem_chat.dart';
import '../services/chat_service.dart';
import '../services/viagem_service.dart';

/// Tela do assistente de IA (RF33–RF40) — chat simples, com histórico
/// salvo no banco, onde o usuário pode tirar dúvidas sobre a viagem
/// ativa, orçamento e gastos.
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
            '"como posso economizar mais nessa viagem?"',
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
