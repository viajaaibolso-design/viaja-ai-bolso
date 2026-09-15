import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cotação de câmbio entre duas moedas, com o momento em que foi obtida
/// (RNF23 exige informar ao usuário a data/hora da última atualização).
class TaxaCambio {
  final double taxa;
  final DateTime atualizadoEm;
  TaxaCambio({required this.taxa, required this.atualizadoEm});
}

/// Conversão de câmbio (RF45/RF46) usando a API pública e gratuita
/// open.er-api.com (sem necessidade de chave). As taxas são cacheadas em
/// memória por algumas horas para não bater na API a cada rebuild de tela.
class CurrencyService {
  static final Map<String, TaxaCambio> _cache = {};
  static const _validadeCache = Duration(hours: 6);

  Future<double> converter(String de, String para, double valor) async {
    if (de == para) return valor;
    final taxa = await _obterTaxa(de, para);
    return valor * taxa;
  }

  Future<double> _obterTaxa(String de, String para) async {
    final chave = '$de-$para';
    final cacheado = _cache[chave];
    if (cacheado != null &&
        DateTime.now().difference(cacheado.atualizadoEm) < _validadeCache) {
      return cacheado.taxa;
    }

    final uri = Uri.parse('https://open.er-api.com/v6/latest/$de');
    final resposta = await http.get(uri).timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível obter a taxa de câmbio');
    }
    final json = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (json['result'] != 'success') {
      throw Exception('Taxa de câmbio indisponível no momento');
    }
    final taxas = json['rates'] as Map<String, dynamic>;
    final valorTaxa = taxas[para];
    if (valorTaxa == null) {
      throw Exception('Moeda "$para" não suportada pela conversão');
    }
    final taxa = (valorTaxa as num).toDouble();
    _cache[chave] = TaxaCambio(taxa: taxa, atualizadoEm: DateTime.now());
    return taxa;
  }

  /// Data/hora (local) da última vez que essa cotação foi buscada nesta
  /// sessão do app, ou null se ainda não foi consultada.
  DateTime? ultimaAtualizacao(String de, String para) =>
      _cache['$de-$para']?.atualizadoEm;
}
