import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _nome = '';
  String _email = '';
  String? _fotoUrl;
  late final String _idUsuario;
  Uint8List? _fotoBytesLocal;
  bool _carregandoFoto = false;
  final _service = AuthService();

  @override
  void initState() {
    super.initState();
    _idUsuario = Supabase.instance.client.auth.currentUser!.id;
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final perfil = await _service.getPerfil(_idUsuario);
      setState(() {
        _nome = perfil.nome;
        _email = perfil.email;
        _fotoUrl = perfil.fotoUrl;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao carregar perfil'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _selecionarFoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _fotoBytesLocal = bytes;
        _carregandoFoto = true;
      });

      final url = await _service.uploadFotoPerfil(_idUsuario, bytes);
      await _service.atualizarPerfil(_idUsuario, _nome, _email, 'BRL',
          fotoUrl: url);

      setState(() {
        _fotoUrl = url;
        _fotoBytesLocal = null;
        _carregandoFoto = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Foto atualizada!'),
            backgroundColor: Colors.green));
      }
    } catch (_) {
      setState(() => _carregandoFoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao selecionar foto'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _logoff() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await _service.logoff();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false);
      }
    }
  }

  Future<void> _editarPerfil() async {
    final nomeCtrl = TextEditingController(text: _nome);
    final emailCtrl = TextEditingController(text: _email);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.atualizarPerfil(
                  _idUsuario, nomeCtrl.text, emailCtrl.text, 'BRL');
              await _carregar();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Perfil atualizado!'),
                    backgroundColor: Colors.green));
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Salvar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _alterarSenha() async {
    final atualCtrl = TextEditingController();
    final novaCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: atualCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha atual',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: novaCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nova senha',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final resultado =
                  await _service.alterarSenha(atualCtrl.text, novaCtrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(resultado['mensagem'] ?? ''),
                    backgroundColor: resultado['code'] == 200
                        ? Colors.green
                        : Colors.red));
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Alterar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  ImageProvider? get _avatarImage {
    if (_fotoBytesLocal != null) return MemoryImage(_fotoBytesLocal!);
    if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      return NetworkImage(_fotoUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Meu perfil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar com botão de editar
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _selecionarFoto,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: kPrimaryColor.withValues(alpha: 0.2),
                      backgroundImage: _avatarImage,
                      child: _avatarImage == null
                          ? const Icon(Icons.person,
                              size: 55, color: kPrimaryColor)
                          : null,
                    ),
                  ),
                  if (_carregandoFoto)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: kPrimaryColor),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _selecionarFoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_nome,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(_email, style: const TextStyle(color: kTextGrey)),
            const SizedBox(height: 32),

            // Opções
            _OpcaoPerfil(
              icone: Icons.edit,
              titulo: 'Editar perfil',
              onTap: _editarPerfil,
            ),
            _OpcaoPerfil(
              icone: Icons.lock_outline,
              titulo: 'Alterar senha',
              onTap: _alterarSenha,
            ),
            _OpcaoPerfil(
              icone: Icons.attach_money,
              titulo: 'Moeda padrão',
              subtitulo: 'BRL - Real (R\$)',
              onTap: () {},
            ),
            _OpcaoPerfil(
              icone: Icons.settings,
              titulo: 'Configurações',
              onTap: () {},
            ),
            _OpcaoPerfil(
              icone: Icons.info_outline,
              titulo: 'Sobre o app',
              onTap: () {},
            ),
            _OpcaoPerfil(
              icone: Icons.support_agent,
              titulo: 'Suporte',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _logoff,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sair da conta',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcaoPerfil extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;
  final VoidCallback onTap;

  const _OpcaoPerfil({
    required this.icone,
    required this.titulo,
    this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icone, color: kPrimaryColor),
        title: Text(titulo),
        subtitle: subtitulo != null ? Text(subtitulo!) : null,
        trailing: const Icon(Icons.chevron_right, color: kTextGrey),
        onTap: onTap,
      ),
    );
  }
}
