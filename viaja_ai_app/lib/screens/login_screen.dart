import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'cadastro_screen.dart';
import 'recuperar_senha_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  bool _verSenha = false;
  final _service = AuthService();

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _senhaCtrl.text.trim().isEmpty) {
      _mostrarErro('Preencha todos os campos');
      return;
    }
    setState(() => _loading = true);
    try {
      final resultado = await _service.login(
          _emailCtrl.text.trim(), _senhaCtrl.text.trim());

      if (resultado['code'] == 200) {
        final usuario = resultado['usuario'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id_usuario', usuario['id_usuario']);
        await prefs.setString('nome', usuario['nome']);
        await prefs.setString('email', usuario['email']);

        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      } else {
        _mostrarErro(resultado['mensagem'] ?? 'Erro ao fazer login');
      }
    } catch (e) {
      _mostrarErro('Erro de conexão com o servidor');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.flight_takeoff, color: kPrimaryColor, size: 50),
              const Text(
                'Viajaí',
                style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
              const Text('Bolso',
                  style: TextStyle(color: kPrimaryLight, fontSize: 16)),
              const SizedBox(height: 48),
              const Text('Bem-vindo de volta!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Faça login para continuar',
                  style: TextStyle(color: kTextGrey)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaCtrl,
                obscureText: !_verSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _verSenha ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _verSenha = !_verSenha),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RecuperarSenhaScreen())),
                  child: const Text('Esqueci minha senha',
                      style: TextStyle(color: kPrimaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Entrar',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ainda não tem conta? '),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const CadastroScreen())),
                    child: const Text('Cadastre-se',
                        style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
