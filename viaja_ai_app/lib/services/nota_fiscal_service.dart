import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resultado_extracao.dart';

/// Leitura automática de notas fiscais por visão computacional
/// (RF48–RF51). Assim como o assistente de IA (ChatService), esta classe
/// NUNCA chama a API de IA diretamente — ela manda a imagem (em base64)
/// para a Edge Function "extrair-nota" do Supabase, que é quem de fato
/// fala com o Gemini usando a chave guardada só no servidor (o mesmo
/// secret GEMINI_API_KEY já configurado para o chat).
class NotaFiscalService {
  final _client = Supabase.instance.client;

  Future<ResultadoExtracao> extrair(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final res = await _client.functions.invoke('extrair-nota', body: {
        'imagemBase64': base64Encode(bytes),
        'mimeType': mimeType,
      });
      if (res.data == null || res.data is! Map) {
        return ResultadoExtracao(
          sucesso: false,
          erro: 'Não foi possível analisar a imagem agora.',
        );
      }
      return ResultadoExtracao.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return ResultadoExtracao(
        sucesso: false,
        erro: 'Não foi possível analisar a imagem agora.',
      );
    }
  }
}
