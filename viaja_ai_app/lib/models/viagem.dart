class Viagem {
  final String? idViagem;
  final String nome;
  final String destino;
  final String? fotoUrl;
  final String dataInicio;
  final String dataFim;
  final double orcamento;
  final double totalGasto;
  final double percentualGasto;
  final String? idUsuario;
  final String moedaLocal;

  Viagem({
    this.idViagem,
    required this.nome,
    required this.destino,
    this.fotoUrl,
    required this.dataInicio,
    required this.dataFim,
    this.orcamento = 0,
    this.totalGasto = 0,
    this.percentualGasto = 0,
    this.idUsuario,
    this.moedaLocal = 'BRL',
  });

  factory Viagem.fromJson(Map<String, dynamic> json) {
    return Viagem(
      idViagem: json['id'] as String?,
      nome: json['nome'] ?? '',
      destino: json['destino'] ?? '',
      fotoUrl: json['foto_url'],
      dataInicio: json['data_inicio'] ?? '',
      dataFim: json['data_fim'] ?? '',
      orcamento: (json['orcamento'] as num? ?? 0).toDouble(),
      totalGasto: (json['total_gasto'] as num? ?? 0).toDouble(),
      percentualGasto: (json['percentual_gasto'] as num? ?? 0).toDouble(),
      idUsuario: json['user_id'] as String?,
      moedaLocal: json['moeda_local'] as String? ?? 'BRL',
    );
  }
}
