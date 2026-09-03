class Viagem {
  final int? idViagem;
  final String nome;
  final String destino;
  final String? foto;
  final String dataInicio;
  final String dataFim;
  final double orcamento;
  final double totalGasto;
  final double percentualGasto;
  final int? idUsuario;

  Viagem({
    this.idViagem,
    required this.nome,
    required this.destino,
    this.foto,
    required this.dataInicio,
    required this.dataFim,
    this.orcamento = 0,
    this.totalGasto = 0,
    this.percentualGasto = 0,
    this.idUsuario,
  });

  factory Viagem.fromJson(Map<String, dynamic> json) {
    return Viagem(
      idViagem: json['id_viagem'],
      nome: json['nome'] ?? '',
      destino: json['destino'] ?? '',
      foto: json['foto'],
      dataInicio: json['data_inicio'] ?? '',
      dataFim: json['data_fim'] ?? '',
      orcamento: (json['orcamento'] ?? 0).toDouble(),
      totalGasto: (json['total_gasto'] ?? 0).toDouble(),
      percentualGasto: (json['percentual_gasto'] ?? 0).toDouble(),
    );
  }
}
