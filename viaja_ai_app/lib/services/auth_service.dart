import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/usuario.dart';

class AuthService {
  Future<Map<String, dynamic>> cadastrar(String nome, String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cadastro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    return jsonDecode(response.body);
  }

  Future<void> logoff(int idUsuario) async {
    await http.post(
      Uri.parse('$baseUrl/logoff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_usuario': idUsuario}),
    );
  }

  Future<Map<String, dynamic>> recuperarSenha(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recuperar-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> redefinirSenha(
      String email, String token, String novaSenha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/redefinir-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token, 'nova_senha': novaSenha}),
    );
    return jsonDecode(response.body);
  }

  Future<Usuario> getPerfil(int idUsuario) async {
    final response = await http.get(Uri.parse('$baseUrl/perfil/$idUsuario'));
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> atualizarPerfil(
      int idUsuario, String nome, String email, String moeda,
      {String? foto}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/atualizarperfil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_usuario': idUsuario,
        'nome': nome,
        'email': email,
        'moeda_padrao': moeda,
        if (foto != null) 'foto': foto,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> alterarSenha(
      int idUsuario, String senhaAtual, String novaSenha) async {
    final response = await http.put(
      Uri.parse('$baseUrl/alterarsenha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_usuario': idUsuario,
        'senha_atual': senhaAtual,
        'nova_senha': novaSenha,
      }),
    );
    return jsonDecode(response.body);
  }
}
