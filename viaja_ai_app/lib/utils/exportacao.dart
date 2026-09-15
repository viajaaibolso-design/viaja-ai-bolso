import '../models/despesa.dart';

/// RF23 — Gera um CSV (compatível com Excel/Google Sheets/LibreOffice) a
/// partir de uma lista de despesas, para prestação de contas da viagem.
String gerarCsvDespesas(List<Despesa> despesas, String moedaLocal) {
  final linhas = StringBuffer();
  // ponto-e-vírgula como separador: abre corretamente no Excel em pt-BR
  // sem precisar de configuração extra de importação.
  linhas.writeln('Data;Descrição;Categoria;Forma de pagamento;Valor ($moedaLocal)');

  String escapar(String texto) {
    final semAspas = texto.replaceAll('"', '""');
    return semAspas.contains(';') || semAspas.contains('"')
        ? '"$semAspas"'
        : semAspas;
  }

  for (final d in despesas) {
    final valorFormatado = d.valor.toStringAsFixed(2).replaceAll('.', ',');
    linhas.writeln([
      escapar(d.data),
      escapar(d.descricao),
      escapar(d.categoria ?? ''),
      escapar(d.formaPagamento),
      valorFormatado,
    ].join(';'));
  }

  final total = despesas.fold<double>(0, (soma, d) => soma + d.valor);
  linhas.writeln();
  linhas.writeln('Total;;;;${total.toStringAsFixed(2).replaceAll('.', ',')}');

  return linhas.toString();
}
