import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mensagem_chat.dart';

/// Agente de vIAgens (RF33–RF47).
///
/// O app NUNCA guarda nem chama a API de IA diretamente. Ele manda a
/// pergunta e o histórico recente para a Edge Function "chat-ia" do
/// Supabase, que é quem de fato conversa com o provedor de IA (Gemini,
/// da Google) usando uma chave guardada só no servidor. Isso é
/// necessário porque, diferente da anonKey do Supabase (pública por
/// design, protegida por RLS), a chave de API de IA é um segredo de
/// verdade — se ela estivesse aqui no app, qualquer pessoa poderia
/// extraí-la abrindo o DevTools na versão web.
class ChatService {
  final _client = Supabase.instance.client;

  String get _idUsuario => _client.auth.currentUser!.id;

  /// Retorna a conversa mais recente do usuário, criando uma nova se ele
  /// ainda não tiver nenhuma. Por enquanto o app trabalha com um único
  /// histórico contínuo por usuário (mais simples pra um app de viagem).
  Future<String> obterOuCriarConversa() async {
    final existentes = await _client
        .from('conversas')
        .select('id')
        .eq('user_id', _idUsuario)
        .order('created_at', ascending: false)
        .limit(1);
    if (existentes.isNotEmpty) {
      return existentes.first['id'] as String;
    }
    final nova = await _client
        .from('conversas')
        .insert({'user_id': _idUsuario, 'titulo': 'Assistente de viagem'})
        .select('id')
        .single();
    return nova['id'] as String;
  }

  Future<List<MensagemChat>> listarMensagens(String conversaId) async {
    final data = await _client
        .from('mensagens')
        .select()
        .eq('conversa_id', conversaId)
        .order('created_at', ascending: true);
    return (data as List)
        .map((m) => MensagemChat.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<MensagemChat> _salvarMensagem(
      String conversaId, String papel, String conteudo) async {
    final salva = await _client
        .from('mensagens')
        .insert({
          'conversa_id': conversaId,
          'papel': papel,
          'conteudo': conteudo,
        })
        .select()
        .single();
    return MensagemChat.fromJson(salva);
  }

  /// Envia a pergunta do usuário, salva-a, aciona a Edge Function e
  /// devolve a mensagem do assistente já salva no histórico.
  ///
  /// [historico] deve conter as mensagens já exibidas na tela (sem
  /// incluir a nova pergunta). [contextoViagem] é um resumo opcional da
  /// viagem ativa (nome, orçamento, total gasto etc.) que ajuda a IA a
  /// responder com base nos dados reais do usuário.
  Future<MensagemChat> enviarMensagem({
    required String conversaId,
    required String mensagem,
    required List<MensagemChat> historico,
    Map<String, dynamic>? contextoViagem,
  }) async {
    await _salvarMensagem(conversaId, 'user', mensagem);

    // Manda só as últimas mensagens pra não deixar a requisição gigante
    // (e mais rápida na API do Gemini).
    final baseHistorico =
        historico.length > 20 ? historico.sublist(historico.length - 20) : historico;

    final corpo = <String, dynamic>{
      'mensagens': [
        ...baseHistorico.map((m) => {'papel': m.papel, 'conteudo': m.conteudo}),
        {'papel': 'user', 'conteudo': mensagem},
      ],
      if (contextoViagem != null) 'contextoViagem': contextoViagem,
    };

    final res = await _client.functions.invoke('chat-ia', body: corpo);

    if (res.status != 200 || res.data == null || res.data['resposta'] == null) {
      final erro = (res.data is Map && res.data['erro'] != null)
          ? res.data['erro'] as String
          : 'Não foi possível falar com o assistente agora. Tente novamente.';
      throw Exception(erro);
    }

    final textoResposta = res.data['resposta'] as String;
    return _salvarMensagem(conversaId, 'assistant', textoResposta);
  }

  /// Monta o texto de resumo da entrevista de planejamento, salvo como a
  /// "pergunta" do usuário no histórico — assim o pedido de roteiro
  /// aparece no chat como uma mensagem normal, igual a qualquer outra.
  String resumirEntrevista(Map<String, dynamic> entrevista) {
    final partes = <String>[
      'Quero planejar uma viagem para ${entrevista['destino']}.'
    ];
    if (entrevista['dataInicio'] != null && entrevista['dataFim'] != null) {
      partes.add(
          'Período: ${entrevista['dataInicio']} a ${entrevista['dataFim']}.');
    }
    if (entrevista['orcamento'] != null &&
        entrevista['orcamento'].toString().isNotEmpty) {
      partes.add('Orçamento aproximado: ${entrevista['orcamento']}.');
    }
    if (entrevista['meioTransporte'] != null) {
      partes.add('Meio de transporte: ${entrevista['meioTransporte']}.');
    }
    if (entrevista['preferencias'] != null &&
        (entrevista['preferencias'] as String).trim().isNotEmpty) {
      partes.add('Preferências: ${entrevista['preferencias']}.');
    }
    partes.add(
        'Monte um roteiro com estimativa de custos e sugestões de passagem, '
        'hospedagem e restaurantes.');
    return partes.join(' ');
  }

  /// Planeja uma viagem nova a partir de uma entrevista (RF33–RF47,
  /// parcial): roteiro com estimativa de custos, sugestões de passagem/
  /// hospedagem/restaurante e, se o meio de transporte for carro, dicas
  /// de estrada. Documentação/vistos/vacinas não fazem parte deste
  /// recurso — seguem pendentes de validação com o orientador, como o
  /// resto do Agente de vIAgens completo.
  ///
  /// Como no chat comum, o app nunca fala direto com o Gemini: tudo
  /// passa pela mesma Edge Function chat-ia, só que com modo:'roteiro'.
  Future<MensagemChat> planejarViagem({
    required String conversaId,
    required Map<String, dynamic> entrevista,
  }) async {
    final resumo = resumirEntrevista(entrevista);
    await _salvarMensagem(conversaId, 'user', resumo);

    final corpo = <String, dynamic>{
      'modo': 'roteiro',
      'entrevista': entrevista,
      'mensagens': [
        {'papel': 'user', 'conteudo': resumo},
      ],
    };

    final res = await _client.functions.invoke('chat-ia', body: corpo);

    if (res.status != 200 || res.data == null || res.data['resposta'] == null) {
      final erro = (res.data is Map && res.data['erro'] != null)
          ? res.data['erro'] as String
          : 'Não foi possível gerar o roteiro agora. Tente novamente.';
      throw Exception(erro);
    }

    final textoResposta = res.data['resposta'] as String;
    return _salvarMensagem(conversaId, 'assistant', textoResposta);
  }
}
