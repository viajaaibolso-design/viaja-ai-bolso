/// Resultado da leitura automática de uma nota fiscal/recibo por visão
/// computacional (RF48–RF51). [sucesso] indica se a IA conseguiu extrair
/// os dados com confiança suficiente (RNF21) — quando false, a tela deve
/// deixar o usuário preencher manualmente em vez de travar o fluxo.
class ResultadoExtracao {
  final bool sucesso;
  final String? estabelecimento;
  final double? valor;
  final String? data; // formato AAAA-MM-DD
  final String? categoria;
  final String? erro;

  ResultadoExtracao({
    required this.sucesso,
    this.estabelecimento,
    this.valor,
    this.data,
    this.categoria,
    this.erro,
  });

  factory ResultadoExtracao.fromJson(Map<String, dynamic> json) {
    final valorJson = json['valor'];
    return ResultadoExtracao(
      sucesso: json['sucesso'] == true,
      estabelecimento: json['estabelecimento'] as String?,
      valor: valorJson is num ? valorJson.toDouble() : null,
      data: json['data'] as String?,
      categoria: json['categoria'] as String?,
      erro: json['erro'] as String?,
    );
  }
}
