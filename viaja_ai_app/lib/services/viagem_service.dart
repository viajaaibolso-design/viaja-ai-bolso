import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/viagem.dart';
import '../models/despesa.dart';

class ViagemService {
  Future<List<Viagem>> listar(int idUsuario) async {
    final response = await http.get(Uri.parse('$baseUrl/viagens/$idUsuario'));
    final List data = jsonDecode(response.body);
    return data.map((e) => Viagem.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> cadastrar(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cadastrarviagem'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> atualizar(Map<String, dynamic> dados) async {
    final response = await http.put(
      Uri.parse('$baseUrl/atualizarviagem'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );
    return jsonDecode(response.body);
  }

  Future<void> remover(int idViagem) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/removerviagem'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'id_viagem': idViagem});
    await request.send();
  }
}

class DespesaService {
  Future<List<Despesa>> listar(int idViagem) async {
    final response = await http.get(Uri.parse('$baseUrl/despesas/$idViagem'));
    final List data = jsonDecode(response.body);
    return data.map((e) => Despesa.fromJson(e)).toList();
  }

  Future<List<Categoria>> listarCategorias() async {
    final response = await http.get(Uri.parse('$baseUrl/categorias'));
    final List data = jsonDecode(response.body);
    return data.map((e) => Categoria.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> cadastrar(Map<String, dynamic> dados) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cadastrardespesa'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> atualizar(Map<String, dynamic> dados) async {
    final response = await http.put(
      Uri.parse('$baseUrl/atualizardespesa'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );
    return jsonDecode(response.body);
  }

  Future<void> remover(int idDespesa) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/removerdespesa'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'id_despesa': idDespesa});
    await request.send();
  }
}

class DashboardService {
  Future<Map<String, dynamic>> getDashboard(int idUsuario) async {
    final response =
        await http.get(Uri.parse('$baseUrl/dashboard/$idUsuario'));
    return jsonDecode(response.body);
  }
}
