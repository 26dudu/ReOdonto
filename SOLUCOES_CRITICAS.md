# 🔧 SOLUÇÕES PARA PROBLEMAS CRÍTICOS

**Arquivo complementar ao CHECKLIST_COMPLETO.md**

---

## ⚠️ PROBLEMA 1: CEP NÃO PREENCHE RUA E BAIRRO AUTOMATICAMENTE

### Localização do código
`frontend/lib/widgets/cadastro/localizacaaoClinica.dart`

### Código atual (ERRADO)
```dart
// Busca CEP mas não faz nada com o resultado
_buscaCep() async {
    final resultado = await ApiService.buscarCep(_controladorCep.text);
    if (resultado.temErro) {
        _mostrarErro(resultado.erro!);
    }
    // ❌ Aqui deveria preencher os controllers!
}
```

### Solução (CORRETO)
Você precisa passar os controllers de rua e bairro para o widget e preenché-los:

**1. Editar `telaCadastro.dart` — passar controllers**
```dart
AddressInfoFields(
  controladorCpf: _controladorCpf,
  controladorCep: _controladorCep,
  controladorRua: _controladorRua,           // ✅ Novo
  controladorBairro: _controladorBairro,     // ✅ Novo
  controladorNumero: _controladorNumero,
),
```

**2. Editar `localizacaaoClinica.dart` — preencher campos**
```dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddressInfoFields extends StatefulWidget {
  final TextEditingController controladorCpf;
  final TextEditingController controladorCep;
  final TextEditingController controladorRua;
  final TextEditingController controladorBairro;
  final TextEditingController controladorNumero;

  const AddressInfoFields({
    super.key,
    required this.controladorCpf,
    required this.controladorCep,
    required this.controladorRua,
    required this.controladorBairro,
    required this.controladorNumero,
  });

  @override
  State<AddressInfoFields> createState() => _AddressInfoFieldsState();
}

class _AddressInfoFieldsState extends State<AddressInfoFields> {
  bool _carregandoCep = false;
  bool _cepPreenchido = false;

  Future<void> _buscaCep() async {
    if (widget.controladorCep.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o CEP primeiro')),
      );
      return;
    }

    setState(() => _carregandoCep = true);

    final resultado = await ApiService.buscarCep(widget.controladorCep.text);

    if (!mounted) return;
    setState(() => _carregandoCep = false);

    if (resultado.temErro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.erro!),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // ✅ AQUI PREENCHE OS CAMPOS AUTOMATICAMENTE
    final dados = resultado.dados!;
    widget.controladorRua.text = dados['logradouro'] ?? '';
    widget.controladorBairro.text = dados['bairro'] ?? '';
    
    // ✅ Marca que CEP foi preenchido
    setState(() => _cepPreenchido = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endereço encontrado!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- CPF ---
        const Text('CPF', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controladorCpf,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Digite seu CPF',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- CEP ---
        const Text('CEP', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controladorCep,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '00000-000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _carregandoCep ? null : _buscaCep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: _carregandoCep
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- RUA (BLOQUEAR SE CEP PREENCHIDO) ---
        const Text('Rua', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controladorRua,
          enabled: !_cepPreenchido,  // ✅ BLOQUEADO após busca
          decoration: InputDecoration(
            hintText: 'Rua (preenchida automaticamente)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: _cepPreenchido,
            fillColor: _cepPreenchido ? Colors.grey[200] : null,
          ),
        ),
        const SizedBox(height: 16),

        // --- BAIRRO (BLOQUEAR SE CEP PREENCHIDO) ---
        const Text('Bairro', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controladorBairro,
          enabled: !_cepPreenchido,  // ✅ BLOQUEADO após busca
          decoration: InputDecoration(
            hintText: 'Bairro (preenchido automaticamente)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: _cepPreenchido,
            fillColor: _cepPreenchido ? Colors.grey[200] : null,
          ),
        ),
        const SizedBox(height: 16),

        // --- NÚMERO ---
        const Text('Número', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controladorNumero,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Número do imóvel',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
```

### Teste
1. Abrir app
2. Ir para cadastro
3. Preencher CEP: `30150380` (sem hífen)
4. Clicar "Buscar"
5. **Esperado:** Rua e Bairro preenchem automaticamente e ficam bloqueados

---

## ⚠️ PROBLEMA 2: TELA DE AGENDAMENTO VAZIA

### Localização do código
`frontend/lib/pages/telaAgenda.dart`

### Código atual (VAZIO)
```dart
// 22 KB de código inútil
class TelaAgenda extends StatefulWidget {
  // ... vazio
}
```

### Solução (BÁSICA)

**Substitua o arquivo `telaAgenda.dart` por:**

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _TelaAgendaState();
}

class _TelaAgendaState extends State<TelaAgenda> {
  late Future<List<dynamic>> _agendamentosFuture;

  @override
  void initState() {
    super.initState();
    _agendamentosFuture = _carregarAgendamentos();
  }

  Future<List<dynamic>> _carregarAgendamentos() async {
    final resultado = await ApiService.listarAgendamentos();
    if (resultado.temErro) {
      throw Exception(resultado.erro);
    }
    return resultado.dados ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _agendamentosFuture,
        builder: (context, snapshot) {
          // Carregando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Erro
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _agendamentosFuture = _carregarAgendamentos();
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          // Sem agendamentos
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Você não tem agendamentos yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navegar para nova página de agendamento
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Em breve: Criar novo agendamento'),
                        ),
                      );
                    },
                    child: const Text('Agendar agora'),
                  ),
                ],
              ),
            );
          }

          // Lista de agendamentos
          final agendamentos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _agendamentosFuture = _carregarAgendamentos();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: agendamentos.length,
              itemBuilder: (context, index) {
                final agendamento = agendamentos[index] as Map<String, dynamic>;
                return _CartaoAgendamento(agendamento: agendamento);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar para nova página de agendamento
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Em breve: Criar novo agendamento'),
            ),
          );
        },
        backgroundColor: AppColors.azulPrimario,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CartaoAgendamento extends StatelessWidget {
  final Map<String, dynamic> agendamento;

  const _CartaoAgendamento({required this.agendamento});

  @override
  Widget build(BuildContext context) {
    final status = agendamento['status'] ?? 'agendado';
    final dataHora = agendamento['data_hora'] ?? '';
    final dentista = agendamento['dentista_nome'] ?? 'Dentista';
    final clinica = agendamento['clinica_nome'] ?? 'Clínica';
    final consulta = agendamento['consulta_nome'] ?? 'Consulta';

    // Cor do status
    Color corStatus;
    switch (status) {
      case 'agendado':
        corStatus = Colors.blue;
        break;
      case 'concluido':
        corStatus = Colors.green;
        break;
      case 'cancelado':
        corStatus = Colors.red;
        break;
      default:
        corStatus = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  consulta,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(status.toUpperCase()),
                  backgroundColor: corStatus.withOpacity(0.2),
                  labelStyle: TextStyle(color: corStatus),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LinhaDado(label: 'Dentista', valor: dentista),
            const SizedBox(height: 8),
            _LinhaDado(label: 'Clínica', valor: clinica),
            const SizedBox(height: 8),
            _LinhaDado(label: 'Data/Hora', valor: dataHora),
            const SizedBox(height: 12),
            if (status == 'agendado')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    // TODO: Cancelar agendamento
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Em breve: Cancelar agendamento'),
                      ),
                    );
                  },
                  child: const Text('Cancelar agendamento'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinhaDado extends StatelessWidget {
  final String label;
  final String valor;

  const _LinhaDado({
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
```

### Teste
1. Fazer login
2. Clicar em "Agendamentos" (no menu quando implementar)
3. **Esperado:** Lista vazia se não há agendamentos, ou lista de agendamentos se houver

---

## ⚠️ PROBLEMA 3: TELA DE PERFIL NÃO EDITA

### Localização do código
`frontend/lib/pages/telaPerfil.dart`

### Adicionar método ao ApiService

**Em `frontend/lib/services/api_service.dart`, adicione:**

```dart
// --- PERFIL ---

static Future<ApiResultado<Map<String, dynamic>>> buscarPerfil(int id) async {
  try {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/pacientes/$id'),
          headers: _headersAuth,
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return ApiResultado.sucesso(body);
    return ApiResultado.falha(body['erro'] ?? 'Erro ao buscar perfil');
  } on SocketException {
    return const ApiResultado.falha('Sem conexão com o servidor.');
  } catch (e) {
    return ApiResultado.falha('Erro inesperado: $e');
  }
}

static Future<ApiResultado<Map<String, dynamic>>> atualizarPerfil(
  int id, {
  required String nome,
  String? email,
  String? telefone,
  String? cpf,
  String? cep,
  String? rua,
  String? bairro,
  String? numero,
}) async {
  try {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/pacientes/$id'),
          headers: _headersAuth,
          body: jsonEncode({
            'nome': nome,
            if (email != null) 'email': email,
            if (telefone != null) 'telefone': telefone,
            if (cpf != null) 'cpf': cpf,
            if (cep != null) 'cep': cep,
            if (rua != null) 'rua': rua,
            if (bairro != null) 'bairro': bairro,
            if (numero != null) 'numero': numero,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return ApiResultado.sucesso(body);
    return ApiResultado.falha(body['erro'] ?? 'Erro ao atualizar perfil');
  } on SocketException {
    return const ApiResultado.falha('Sem conexão com o servidor.');
  } catch (e) {
    return ApiResultado.falha('Erro inesperado: $e');
  }
}
```

### Substituir `telaPerfil.dart`

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sessao_usuario.dart';
import '../theme/app_colors.dart';
import 'telaLogin.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  late Future<Map<String, dynamic>> _perfilFuture;
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _cpfController;
  late TextEditingController _cepController;
  late TextEditingController _ruaController;
  late TextEditingController _bairroController;
  late TextEditingController _numeroController;

  bool _editando = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _emailController = TextEditingController();
    _telefoneController = TextEditingController();
    _cpfController = TextEditingController();
    _cepController = TextEditingController();
    _ruaController = TextEditingController();
    _bairroController = TextEditingController();
    _numeroController = TextEditingController();

    _perfilFuture = _carregarPerfil();
  }

  Future<Map<String, dynamic>> _carregarPerfil() async {
    final resultado = await ApiService.buscarPerfil(SessaoUsuario.id!);
    if (resultado.temErro) {
      throw Exception(resultado.erro);
    }
    final dados = resultado.dados!;
    _preencherControllers(dados);
    return dados;
  }

  void _preencherControllers(Map<String, dynamic> dados) {
    _nomeController.text = dados['nome'] ?? '';
    _emailController.text = dados['email'] ?? '';
    _telefoneController.text = dados['telefone'] ?? '';
    _cpfController.text = dados['cpf'] ?? '';
    _cepController.text = dados['cep'] ?? '';
    _ruaController.text = dados['rua'] ?? '';
    _bairroController.text = dados['bairro'] ?? '';
    _numeroController.text = dados['numero'] ?? '';
  }

  Future<void> _salvarPerfil() async {
    setState(() => _salvando = true);

    final resultado = await ApiService.atualizarPerfil(
      SessaoUsuario.id!,
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      cpf: _cpfController.text,
      cep: _cepController.text,
      rua: _ruaController.text,
      bairro: _bairroController.text,
      numero: _numeroController.text,
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    if (resultado.temErro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.erro!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await SessaoUsuario.salvar({'paciente': resultado.dados});
    setState(() => _editando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await SessaoUsuario.limpar();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TelaLogin()),
              );
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: Colors.white,
        actions: [
          if (!_editando)
            IconButton(
              onPressed: () => setState(() => _editando = true),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro: ${snapshot.error}'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _campoTexto('Nome', _nomeController, !_editando),
                _campoTexto('Email', _emailController, !_editando),
                _campoTexto('Telefone', _telefoneController, !_editando),
                _campoTexto('CPF', _cpfController, !_editando),
                _campoTexto('CEP', _cepController, !_editando),
                _campoTexto('Rua', _ruaController, !_editando),
                _campoTexto('Bairro', _bairroController, !_editando),
                _campoTexto('Número', _numeroController, !_editando),
                const SizedBox(height: 24),
                if (_editando) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _editando = false);
                        _perfilFuture = _carregarPerfil();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller,
    bool desabilitado,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !desabilitado,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: desabilitado,
            fillColor: desabilitado ? Colors.grey[200] : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
```

### Teste
1. Fazer login
2. Ir para Perfil
3. Clicar ícone de lápis (editar)
4. Modificar nome
5. Clicar "Salvar"
6. **Esperado:** Dados salvos e confirmação com SnackBar verde

---

## ⚠️ PROBLEMA 4: VALIDAÇÃO DE CPF REAL

### Solução: Criar arquivo de utilidades

**Novo arquivo:** `frontend/lib/utils/validadores.dart`

```dart
/// Valida CPF pelo algoritmo de dígito verificador
bool validarCpf(String cpf) {
  // Remove símbolos
  String cpfLimpo = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  // Deve ter 11 dígitos
  if (cpfLimpo.length != 11) return false;

  // Não pode ter todos os dígitos iguais
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpfLimpo)) return false;

  // Calcula primeiro dígito verificador
  int soma = 0;
  for (int i = 0; i < 9; i++) {
    soma += int.parse(cpfLimpo[i]) * (10 - i);
  }
  int digito1 = 11 - (soma % 11);
  digito1 = digito1 > 9 ? 0 : digito1;

  // Calcula segundo dígito verificador
  soma = 0;
  for (int i = 0; i < 10; i++) {
    soma += int.parse(cpfLimpo[i]) * (11 - i);
  }
  int digito2 = 11 - (soma % 11);
  digito2 = digito2 > 9 ? 0 : digito2;

  // Compara
  return digito1 == int.parse(cpfLimpo[9]) &&
      digito2 == int.parse(cpfLimpo[10]);
}
```

### Usar na tela de cadastro

**Em `telaCadastro.dart`, editar `_validarDadosPessoais()`:**

```dart
import '../utils/validadores.dart';

bool _validarDadosPessoais() {
  final cpf = _controladorCpf.text.trim();
  
  // ... outras validações ...

  if (!validarCpf(cpf)) {
    _mostrarErro('CPF inválido');
    return false;
  }

  return true;
}
```

### Teste
1. Tentar cadastrar com CPF fake: `11111111111`
2. **Esperado:** Erro "CPF inválido"
3. Tentar com CPF válido: `123.456.789-09` (com verificadores corretos)
4. **Esperado:** Aceita

---

## ✅ RESUMO DAS SOLUÇÕES

| Problema | Status | Tempo |
|----------|--------|-------|
| CEP não preenche automático | Solução fornecida | 30 min |
| Tela de agendamento vazia | Solução fornecida | 30 min |
| Tela de perfil não edita | Solução fornecida | 45 min |
| Validação de CPF | Solução fornecida | 15 min |
| **Total** | **Todas** | **2 horas** |

---

## 🚀 Próximos passos

Depois de implementar estas soluções:

1. **Testar tudo:** Login → Cadastro → Perfil → Agendamentos
2. **Implementar menu:** Drawer ou sanduíche com navegação
3. **Criar modal de novo agendamento:** Com seleção de clínica/dentista/consulta/hora
4. **Testes automatizados:** Widget tests + integration tests

---

**Última atualização:** 24/08/2026
