import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import 'storage_service.dart';

/// Autenticação e perfil, agora via Supabase Auth + tabela public.profiles
/// (antes falava com um backend próprio em baseUrl). Os métodos continuam
/// devolvendo Map com 'code'/'mensagem' para não exigir mudanças grandes
/// nas telas que já tratavam esse formato.
class AuthService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> cadastrar(
      String nome, String email, String senha) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: senha,
        data: {'nome': nome},
      );
      return {
        'code': 200,
        'mensagem':
            'Conta criada! Verifique seu e-mail para confirmar o cadastro.',
      };
    } on AuthException catch (e) {
      return {'code': 400, 'mensagem': e.message};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro de conexão com o servidor'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    try {
      final res =
          await _client.auth.signInWithPassword(email: email, password: senha);
      if (res.user == null) {
        return {'code': 401, 'mensagem': 'E-mail ou senha inválidos'};
      }
      return {'code': 200};
    } on AuthException catch (e) {
      return {'code': 401, 'mensagem': e.message};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro de conexão com o servidor'};
    }
  }

  Future<void> logoff() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>> recuperarSenha(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return {'code': 200, 'mensagem': 'Código enviado para o e-mail!'};
    } on AuthException catch (e) {
      return {'code': 400, 'mensagem': e.message};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro de conexão com o servidor'};
    }
  }

  Future<Map<String, dynamic>> redefinirSenha(
      String email, String token, String novaSenha) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: token,
      );
      await _client.auth.updateUser(UserAttributes(password: novaSenha));
      return {'code': 200, 'mensagem': 'Senha redefinida com sucesso!'};
    } on AuthException catch (e) {
      return {'code': 400, 'mensagem': e.message};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro de conexão com o servidor'};
    }
  }

  Future<Usuario> getPerfil(String idUsuario) async {
    final data =
        await _client.from('profiles').select().eq('id', idUsuario).single();
    return Usuario.fromJson(data);
  }

  Future<Map<String, dynamic>> atualizarPerfil(
    String idUsuario,
    String nome,
    String email,
    String moeda, {
    String? fotoUrl,
  }) async {
    try {
      final atual = _client.auth.currentUser;
      if (atual != null && email.trim() != atual.email) {
        // Muda o e-mail de login (o Supabase envia confirmação para o
        // endereço novo antes de efetivar a troca).
        await _client.auth.updateUser(UserAttributes(email: email.trim()));
      }
      await _client.from('profiles').update({
        'nome': nome,
        'email': email.trim(),
        'moeda_padrao': moeda,
        if (fotoUrl != null) 'foto_url': fotoUrl,
      }).eq('id', idUsuario);
      return {'code': 200, 'mensagem': 'Perfil atualizado!'};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro de conexão com o servidor'};
    }
  }

  Future<Map<String, dynamic>> alterarSenha(
      String senhaAtual, String novaSenha) async {
    try {
      final email = _client.auth.currentUser?.email;
      if (email == null) {
        return {'code': 401, 'mensagem': 'Sessão expirada, faça login novamente'};
      }
      // Reautentica com a senha atual antes de trocar, para confirmar que
      // é realmente o dono da conta.
      await _client.auth.signInWithPassword(email: email, password: senhaAtual);
      await _client.auth.updateUser(UserAttributes(password: novaSenha));
      return {'code': 200, 'mensagem': 'Senha alterada com sucesso!'};
    } on AuthException catch (_) {
      return {'code': 400, 'mensagem': 'Senha atual incorreta'};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro de conexão com o servidor'};
    }
  }

  Future<String> uploadFotoPerfil(String idUsuario, Uint8List bytes) {
    return StorageService().upload('$idUsuario/perfil.jpg', bytes);
  }
}
