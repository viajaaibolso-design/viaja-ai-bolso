class Usuario {
  final int idUsuario;
  final String nome;
  final String email;
  final String? foto;
  final String moedaPadrao;
  final String? token;

  Usuario({
    required this.idUsuario,
    required this.nome,
    required this.email,
    this.foto,
    this.moedaPadrao = 'BRL',
    this.token,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      foto: json['foto'],
      moedaPadrao: json['moeda_padrao'] ?? 'BRL',
      token: json['token'],
    );
  }
}
