import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Upload de arquivos (fotos de perfil e de viagens) para o bucket
/// público "fotos" no Supabase Storage. Cada caminho é prefixado com o
/// id do usuário dono do arquivo, pois é isso que as políticas de RLS do
/// bucket (ver supabase/schema.sql) exigem para permitir escrita.
class StorageService {
  final _client = Supabase.instance.client;

  Future<String> upload(String caminho, Uint8List bytes) async {
    await _client.storage.from('fotos').uploadBinary(
          caminho,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    // cache-buster: evita que a tela mostre uma versão antiga em cache
    // depois de substituir a mesma foto.
    final url = _client.storage.from('fotos').getPublicUrl(caminho);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
