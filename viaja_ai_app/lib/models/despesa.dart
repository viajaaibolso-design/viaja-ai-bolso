class Despesa {
  final int? idDespesa;
  final String descricao;
  final double valor;
  final String data;
  final String? hora;
  final String formaPagamento;
  final int idViagem;
  final int idCategoria;
  final String? categoria;
  final String? icone;

  Despesa({
    this.idDespesa,
    required this.descricao,
    required this.valor,
    required this.data,
    this.hora,
    this.formaPagamento = 'Cartão de crédito',
    required this.idViagem,
    required this.idCategoria,
    this.categoria,
    this.icone,
  });

  factory Despesa.fromJson(Map<String, dynamic> json) {
    return Despesa(
      idDespesa: json['id_despesa'],
      descricao: json['descricao'] ?? '',
      valor: (json['valor'] ?? 0).toDouble(),
      data: json['data'] ?? '',
      hora: json['hora'],
      formaPagamento: json['forma_pagamento'] ?? 'Cartão de crédito',
      idViagem: json['id_viagem_fk'] ?? 0,
      idCategoria: json['id_categoria_fk'] ?? 0,
      categoria: json['categoria'],
      icone: json['icone'],
    );
  }
}

class Categoria {
  final int idCategoria;
  final String nome;
  final String icone;

  Categoria({
    required this.idCategoria,
    required this.nome,
    required this.icone,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['id_categoria'],
      nome: json['nome'] ?? '',
      icone: json['icone'] ?? '',
    );
  }
}
