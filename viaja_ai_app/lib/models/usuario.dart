class Usuario {
  final String idUsuario;
  final String nome;
  final String email;
  final String? fotoUrl;
  final String moedaPadrao;

  Usuario({
    required this.idUsuario,
    required this.nome,
    required this.email,
    this.fotoUrl,
    this.moedaPadrao = 'BRL',
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id'] as String? ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      fotoUrl: json['foto_url'],
      moedaPadrao: json['moeda_padrao'] ?? 'BRL',
    );
  }
}
