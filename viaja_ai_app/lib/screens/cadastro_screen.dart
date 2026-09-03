import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();
  bool _loading = false;
  bool _verSenha = false;
  bool _verConfirmar = false;
  bool _aceitouTermos = false;
  final _service = AuthService();

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _cadastrar() async {
    if (_nomeCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _senhaCtrl.text.trim().isEmpty) {
      _mostrarErro('Preencha todos os campos');
      return;
    }
    if (_senhaCtrl.text != _confirmarSenhaCtrl.text) {
      _mostrarErro('As senhas não coincidem');
      return;
    }
    if (!_aceitouTermos) {
      _mostrarErro('Aceite os Termos de Uso para continuar');
      return;
    }

    setState(() => _loading = true);
    try {
      final resultado = await _service.cadastrar(
          _nomeCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _senhaCtrl.text.trim());

      if (resultado['code'] == 200) {
        _mostrarSucesso('Conta criada com sucesso!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        _mostrarErro(resultado['mensagem'] ?? 'Erro ao cadastrar');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.flight_takeoff, color: kPrimaryColor, size: 40),
                    Text('Viajaí',
                        style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    Text('Bolso',
                        style: TextStyle(color: kPrimaryLight, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Criar conta',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Preencha seus dados para começar a usar o Viajaí Bolso',
                  style: TextStyle(color: kTextGrey, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: _nomeCtrl,
                decoration: InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              TextField(
                controller: _confirmarSenhaCtrl,
                obscureText: !_verConfirmar,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_verConfirmar
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _verConfirmar = !_verConfirmar),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _aceitouTermos,
                    activeColor: kPrimaryColor,
                    onChanged: (v) =>
                        setState(() => _aceitouTermos = v ?? false),
                  ),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Li e aceito os ',
                        children: [
                          TextSpan(
                              text: 'Termos de Uso\ne Política de Privacidade',
                              style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cadastrar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Já tem conta? ',
                      children: [
                        TextSpan(
                            text: 'Entrar',
                            style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
