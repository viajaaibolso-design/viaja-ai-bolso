import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  bool _loading = false;
  bool _codigoEnviado = false;
  final _service = AuthService();

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _enviarCodigo() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _mostrarErro('Digite seu e-mail');
      return;
    }
    setState(() => _loading = true);
    try {
      final resultado = await _service.recuperarSenha(_emailCtrl.text.trim());
      if (resultado['code'] == 200) {
        _mostrarSucesso('Código enviado para o e-mail!');
        setState(() => _codigoEnviado = true);
      } else {
        _mostrarErro(resultado['mensagem'] ?? 'Erro ao enviar código');
      }
    } catch (_) {
      _mostrarErro('Erro de conexão com o servidor');
    }
    setState(() => _loading = false);
  }

  Future<void> _redefinirSenha() async {
    if (_tokenCtrl.text.trim().isEmpty || _novaSenhaCtrl.text.trim().isEmpty) {
      _mostrarErro('Preencha todos os campos');
      return;
    }
    setState(() => _loading = true);
    try {
      final resultado = await _service.redefinirSenha(
          _emailCtrl.text.trim(),
          _tokenCtrl.text.trim(),
          _novaSenhaCtrl.text.trim());

      if (resultado['code'] == 200) {
        _mostrarSucesso('Senha redefinida com sucesso!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        _mostrarErro(resultado['mensagem'] ?? 'Código inválido ou expirado');
      }
    } catch (_) {
      _mostrarErro('Erro de conexão com o servidor');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recuperar senha',
            style: TextStyle(color: kTextDark, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_reset, color: kPrimaryColor, size: 60),
            const SizedBox(height: 16),
            const Text('Esqueceu sua senha?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text(
                'Digite seu e-mail e enviaremos um código de recuperação.',
                style: TextStyle(color: kTextGrey)),
            const SizedBox(height: 32),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              enabled: !_codigoEnviado,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(Icons.email_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (!_codigoEnviado) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _enviarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar código',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
            if (_codigoEnviado) ...[
              const SizedBox(height: 24),
              const Text('Digite o código recebido no e-mail e sua nova senha:',
                  style: TextStyle(color: kTextGrey)),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenCtrl,
                decoration: InputDecoration(
                  labelText: 'Código de recuperação',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _novaSenhaCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _redefinirSenha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Redefinir senha',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _codigoEnviado = false),
                  child: const Text('Reenviar código',
                      style: TextStyle(color: kPrimaryColor)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
