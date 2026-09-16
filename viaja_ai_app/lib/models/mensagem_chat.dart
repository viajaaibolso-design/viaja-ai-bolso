/// Mensagem trocada com o assistente de IA (RF33–RF40).
/// [papel] é 'user' (pergunta do usuário) ou 'assistant' (resposta da IA).
class MensagemChat {
  final String? id;
  final String conversaId;
  final String papel;
  final String conteudo;
  final DateTime? criadoEm;

  MensagemChat({
    this.id,
    required this.conversaId,
    required this.papel,
    required this.conteudo,
    this.criadoEm,
  });

  bool get isUsuario => papel == 'user';

  factory MensagemChat.fromJson(Map<String, dynamic> json) {
    return MensagemChat(
      id: json['id'] as String?,
      conversaId: json['conversa_id'] as String,
      papel: json['papel'] as String,
      conteudo: json['conteudo'] as String,
      criadoEm: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'conversa_id': conversaId,
        'papel': papel,
        'conteudo': conteudo,
      };
}
