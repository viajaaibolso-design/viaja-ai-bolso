class Despesa {
  final String? idDespesa;
  final String descricao;
  final double valor;
  final String data;
  final String? hora;
  final String formaPagamento;
  final String idViagem;
  final String idCategoria;
  final String? categoria;
  final String? icone;
  final String? fotoUrl;

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
    this.fotoUrl,
  });

  factory Despesa.fromJson(Map<String, dynamic> json) {
    // Quando a consulta usa o embed "categorias(nome, icone)", o Supabase
    // devolve um objeto aninhado em json['categorias'].
    final categoriaJson = json['categorias'] as Map<String, dynamic>?;
    return Despesa(
      idDespesa: json['id'] as String?,
      descricao: json['descricao'] ?? '',
      valor: (json['valor'] as num? ?? 0).toDouble(),
      data: json['data'] ?? '',
      hora: json['hora'],
      formaPagamento: json['forma_pagamento'] ?? 'Cartão de crédito',
      idViagem: json['viagem_id'] ?? '',
      idCategoria: json['categoria_id'] ?? '',
      categoria: json['categoria'] ?? categoriaJson?['nome'],
      icone: json['icone'] ?? categoriaJson?['icone'],
      fotoUrl: json['foto_url'] as String?,
    );
  }
}

class Categoria {
  final String idCategoria;
  final String nome;
  final String icone;

  Categoria({
    required this.idCategoria,
    required this.nome,
    required this.icone,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['id'] as String? ?? '',
      nome: json['nome'] ?? '',
      icone: json['icone'] ?? '',
    );
  }
}
