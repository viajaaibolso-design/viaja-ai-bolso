import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/viagem.dart';
import '../models/despesa.dart';

/// CRUD de viagens direto no Postgres do Supabase. A segurança (cada
/// usuário só vê/edita as próprias viagens) é garantida pelas políticas
/// de RLS definidas em supabase/schema.sql — não precisa ser reforçada
/// aqui no client.
class ViagemService {
  final _client = Supabase.instance.client;

  Future<List<Viagem>> listar(String idUsuario) async {
    final data = await _client
        .from('viagens_resumo')
        .select()
        .eq('user_id', idUsuario)
        .order('data_inicio', ascending: false);
    return (data as List)
        .map((e) => Viagem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> cadastrar(Map<String, dynamic> dados) async {
    try {
      await _client.from('viagens').insert(dados);
      return {'code': 200};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro ao salvar viagem'};
    }
  }

  Future<Map<String, dynamic>> atualizar(Map<String, dynamic> dados) async {
    try {
      final payload = Map<String, dynamic>.from(dados);
      final id = payload.remove('id_viagem');
      await _client.from('viagens').update(payload).eq('id', id);
      return {'code': 200};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro ao atualizar viagem'};
    }
  }

  Future<void> remover(String idViagem) async {
    await _client.from('viagens').delete().eq('id', idViagem);
  }

  /// RF14 — define manualmente qual viagem é a "ativa" exibida no
  /// dashboard. Passar null volta ao comportamento automático (viagem em
  /// andamento pela data, ou a mais recente).
  ///
  /// Retorna true se conseguiu salvar. Se a migração v4 (coluna
  /// viagem_ativa_id em profiles) ainda não tiver sido aplicada no banco,
  /// retorna false em vez de lançar exceção.
  Future<bool> definirViagemAtiva(String idUsuario, String? idViagem) async {
    try {
      await _client
          .from('profiles')
          .update({'viagem_ativa_id': idViagem}).eq('id', idUsuario);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class DespesaService {
  final _client = Supabase.instance.client;

  Future<List<Despesa>> listar(String idViagem) async {
    final data = await _client
        .from('despesas')
        .select('*, categorias(nome, icone)')
        .eq('viagem_id', idViagem)
        .order('data', ascending: false);
    return (data as List)
        .map((e) => Despesa.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Categoria>> listarCategorias() async {
    final data = await _client.from('categorias').select().order('nome');
    return (data as List)
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> cadastrar(Map<String, dynamic> dados) async {
    try {
      await _client.from('despesas').insert(dados);
      return {'code': 200};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro ao salvar despesa'};
    }
  }

  Future<Map<String, dynamic>> atualizar(Map<String, dynamic> dados) async {
    try {
      final payload = Map<String, dynamic>.from(dados);
      final id = payload.remove('id_despesa');
      await _client.from('despesas').update(payload).eq('id', id);
      return {'code': 200};
    } catch (_) {
      return {'code': 500, 'mensagem': 'Erro ao atualizar despesa'};
    }
  }

  Future<void> remover(String idDespesa) async {
    await _client.from('despesas').delete().eq('id', idDespesa);
  }
}

class DashboardService {
  final _client = Supabase.instance.client;

  String _hojeIso() {
    final hoje = DateTime.now();
    return '${hoje.year.toString().padLeft(4, '0')}-'
        '${hoje.month.toString().padLeft(2, '0')}-'
        '${hoje.day.toString().padLeft(2, '0')}';
  }

  /// Monta, a partir de algumas consultas simples, o mesmo formato de
  /// resposta que o backend antigo devolvia em GET /dashboard/:id — assim
  /// a DashboardScreen não precisa mudar quase nada.
  Future<Map<String, dynamic>> getDashboard(String idUsuario) async {
    final hojeStr = _hojeIso();

    // Busca isolada e tolerante a falha: se a migração v4 (coluna
    // viagem_ativa_id) ainda não tiver sido aplicada no banco, o resto do
    // dashboard continua funcionando normalmente (cai no fallback
    // automático por data, como antes da v4).
    String? viagemAtivaId;
    try {
      final perfil = await _client
          .from('profiles')
          .select('viagem_ativa_id')
          .eq('id', idUsuario)
          .single();
      viagemAtivaId = perfil['viagem_ativa_id'] as String?;
    } catch (_) {
      viagemAtivaId = null;
    }

    final viagens = await _client
        .from('viagens_resumo')
        .select()
        .eq('user_id', idUsuario)
        .order('data_inicio', ascending: false);

    Map<String, dynamic>? viagemAtiva;

    // RF14: se o usuário escolheu manualmente uma viagem ativa, ela tem
    // prioridade sobre a detecção automática por data.
    if (viagemAtivaId != null) {
      for (final v in viagens) {
        if (v['id'] == viagemAtivaId) {
          viagemAtiva = v as Map<String, dynamic>;
          break;
        }
      }
    }

    if (viagemAtiva == null) {
      for (final v in viagens) {
        final inicio = v['data_inicio'] as String? ?? '';
        final fim = v['data_fim'] as String? ?? '';
        if (inicio.compareTo(hojeStr) <= 0 && fim.compareTo(hojeStr) >= 0) {
          viagemAtiva = v as Map<String, dynamic>;
          break;
        }
      }
    }
    viagemAtiva ??= viagens.isNotEmpty ? viagens.first as Map<String, dynamic> : null;

    // RLS já restringe as despesas às viagens do usuário logado, então
    // não é preciso filtrar por usuário aqui de novo.
    final despesasHoje = await _client
        .from('despesas')
        .select('valor')
        .eq('data', hojeStr);
    double totalHoje = 0;
    for (final d in despesasHoje) {
      totalHoje += (d['valor'] as num).toDouble();
    }

    final maiores = await _client
        .from('despesas')
        .select('valor, categorias(nome)')
        .order('valor', ascending: false)
        .limit(1);
    Map<String, dynamic>? maiorGasto;
    if (maiores.isNotEmpty) {
      final m = maiores.first as Map<String, dynamic>;
      final cat = m['categorias'] as Map<String, dynamic>?;
      maiorGasto = {'valor': m['valor'], 'categoria': cat?['nome']};
    }

    final ultimas = await _client
        .from('despesas')
        .select('descricao, valor, data, hora, categorias(nome, icone)')
        .order('created_at', ascending: false)
        .limit(5);
    final ultimasFormatadas = (ultimas as List).map((e) {
      final d = e as Map<String, dynamic>;
      final cat = d['categorias'] as Map<String, dynamic>?;
      return {
        'descricao': d['descricao'],
        'valor': d['valor'],
        'data': d['data'],
        'hora': d['hora'],
        'categoria': cat?['nome'],
        'icone': cat?['icone'],
      };
    }).toList();

    return {
      'viagem_ativa': viagemAtiva,
      'gastos_hoje': {'total': totalHoje, 'quantidade': despesasHoje.length},
      'maior_gasto': maiorGasto,
      'ultimas_despesas': ultimasFormatadas,
    };
  }
}
