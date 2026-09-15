/// Lista de moedas suportadas para o destino da viagem (RF45) e para a
/// moeda de conversão/padrão do usuário (RF29, RF46). Mantida pequena e
/// fixa (sem consultar API externa) para não depender de rede só para
/// listar opções.
const Map<String, String> kMoedas = {
  'BRL': 'Real brasileiro',
  'USD': 'Dólar americano',
  'EUR': 'Euro',
  'GBP': 'Libra esterlina',
  'ARS': 'Peso argentino',
  'CLP': 'Peso chileno',
  'UYU': 'Peso uruguaio',
  'PYG': 'Guarani paraguaio',
  'MXN': 'Peso mexicano',
  'COP': 'Peso colombiano',
  'PEN': 'Sol peruano',
  'JPY': 'Iene japonês',
  'CNY': 'Yuan chinês',
  'CAD': 'Dólar canadense',
  'AUD': 'Dólar australiano',
  'CHF': 'Franco suíço',
  'ILS': 'Novo shekel israelense',
  'ZAR': 'Rand sul-africano',
};

String simboloMoeda(String codigo) {
  switch (codigo) {
    case 'BRL':
      return 'R\$';
    case 'USD':
      return 'US\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'JPY':
      return '¥';
    case 'CNY':
      return '¥';
    case 'ARS':
      return 'AR\$';
    case 'CLP':
      return 'CL\$';
    case 'UYU':
      return '\$U';
    case 'PYG':
      return '₲';
    case 'MXN':
      return 'MX\$';
    case 'COP':
      return 'CO\$';
    case 'PEN':
      return 'S/';
    case 'CAD':
      return 'CA\$';
    case 'AUD':
      return 'AU\$';
    case 'CHF':
      return 'CHF';
    case 'ILS':
      return '₪';
    case 'ZAR':
      return 'R';
    default:
      return codigo;
  }
}

/// Formata um valor numérico com o símbolo da moeda informada, no padrão
/// brasileiro de separador decimal (vírgula).
String formatarMoeda(double valor, String codigo) {
  final texto = valor.toStringAsFixed(2).replaceAll('.', ',');
  return '${simboloMoeda(codigo)} $texto';
}
