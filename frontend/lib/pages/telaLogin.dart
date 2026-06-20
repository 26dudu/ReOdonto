import 'package:flutter/material.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool _ocultarSenha = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 248, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD0E2FF),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_history_outlined,
                      color: Color(0xFF1E5FD8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C1A2),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'AGENDA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C2434),
                          height: 0.9,
                        ),
                      ),
                      Text(
                        'CHEIA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2434),
                        ),
                      ),
                      Text(
                        'CLÍNICAS ODONTOLÓGICAS - AGENDAMENTO ONLINE',
                        style: TextStyle(fontSize: 6, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Faça login em sua conta ',
                    style: TextStyle(fontSize: 16, color: Color(0xFF1C2434)),
                  ),
                  const Text(
                    'ReOdonto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E5FD8),
                    ),
                  ),
                  const Text(
                    '!',
                    style: TextStyle(fontSize: 16, color: Color(0xFF1C2434)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Digite seu email',
                  hintStyle: const TextStyle(color: Colors.black26),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color.fromARGB(255, 88, 92, 100),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Senha',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 88, 92, 100),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: senhaController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  hintText: 'Digite sua senha',
                  hintStyle: const TextStyle(color: Colors.black26),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color.fromARGB(255, 88, 92, 100),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black45,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarSenha = !_ocultarSenha;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(color: Color(0xFF00C1A2), fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  String email = emailController.text;
                  String senha = senhaController.text;

                  if (!email.contains('@') || email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Digite um email válido')),
                    );
                  } else if (senha.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Digite a senha correta')),
                    );
                  } else {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5FD8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ainda não tem uma conta? ',
                    style: TextStyle(fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Cadastre-se',
                      style: TextStyle(
                        color: Color(0xFF1E5FD8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Row(
                children: [
                  Expanded(
                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ou', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(
                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
