# 🧪 GUIA COMPLETO DE TESTES E DEBUG

---

## 🔧 SETUP INICIAL

### 1. Verificar se Python está instalado
```bash
python --version
# ou
python3 --version
```

### 2. Instalar dependências do backend
```bash
cd backend
pip install -r requirements.txt
```

### 3. Verificar Flutter
```bash
flutter --version
flutter doctor
```

---

## ▶️ INICIAR O BACKEND

### Opção 1: Windows (CMD)
```bash
cd c:\Users\yslan\Desktop\ProjetoFinal\ReOdonto\backend
python app.py
```

**Esperado:**
```
 * Serving Flask app 'app'
 * Running on http://0.0.0.0:5000
```

### Opção 2: Windows (PowerShell)
```powershell
cd c:\Users\yslan\Desktop\ProjetoFinal\ReOdonto\backend
python app.py
```

### Verificar se backend está rodando
```bash
curl http://127.0.0.1:5000/pacientes/ -X GET -H "Authorization: Bearer fake-token"
```

**Esperado:** Erro 401 (porque token é fake) mas a conexão funcionou!

---

## ▶️ INICIAR O FRONTEND

### 1. Emulador Android
```bash
# Abrir o Android Emulator antes (via Android Studio)
cd c:\Users\yslan\Desktop\ProjetoFinal\ReOdonto\frontend
flutter run
```

### 2. iOS Simulator (se tiver Mac)
```bash
flutter run -d ios
```

### 3. Web (teste rápido)
```bash
flutter run -d chrome
```

### 4. Dispositivo físico
```bash
# Conecte o telefone via USB, depois:
flutter run
```

---

## 🧪 TESTES MANUAIS

### Teste 1: Registrar novo paciente

**Pré-requisitos:**
- Backend rodando em `http://0.0.0.0:5000`
- App Flutter aberto

**Passos:**
1. Clicar "Cadastre-se"
2. Preencher:
   - Nome: "João Silva"
   - Email: "joao@teste.com"
   - Telefone: "(31) 98765-4321"
3. Clicar "Continuar"
4. Preencher:
   - CEP: "30150380"
   - Clicar "Buscar"
5. Verificar se rua/bairro preenchem
6. Preencher número: "123"
7. Clicar "Continuar"
8. Preencher:
   - Senha: "123456"
   - Confirmar: "123456"
9. Clicar "Criar conta"

**Resultado esperado:** ✅ Conta criada, volta para login

**Se falhar:**
```bash
# No terminal do backend, verificar logs
# Procurar por: [ERROR] ou [WARNING]
```

---

### Teste 2: Fazer login

**Pré-requisitos:**
- Conta criada no Teste 1

**Passos:**
1. Na tela de login
2. Email: "joao@teste.com"
3. Senha: "123456"
4. Clicar "Entrar"

**Resultado esperado:** ✅ Bem-vindo, João Silva! (SnackBar)

**Se falhar - Erro "Email ou senha inválidos":**
```bash
# Verificar no banco se o usuário foi criado
# Abrir: backend/database/odonto.db (com SQLite Browser)
# Tabela: paciente
```

---

### Teste 3: Fechar e reabrir app (verificar sessão)

**Pré-requisitos:**
- Já fez login no Teste 2

**Passos:**
1. Fechar o app
2. Reabrir o app
3. Aguardar

**Resultado esperado:** ✅ App NÃO pede login de novo (sessão persistida)

**Se pedir login de novo:**
- ❌ Problema: `SessaoUsuario.carregar()` não está sendo chamado em `main.dart`
- Solução: Ver seção "PROBLEMA 5: Sem session recovery" no CHECKLIST

---

### Teste 4: Busca de CEP

**Passos:**
1. Ir para cadastro
2. Preencher CEP: "30150380"
3. Clicar "Buscar"

**Resultado esperado:**
```
✅ Rua preenchida: "Avenida Getúlio Vargas" (ou similar)
✅ Bairro preenchido: "Centro" (ou similar)
✅ Campos bloqueados (cinzento)
```

**Se retornar erro "CEP não encontrado":**
- CEP é inválido mesmo
- Tentar outro: "30150-380" (com hífen)

**Se retornar erro "Sem conexão":**
- Verificar internet
- Verificar se backend está rodando
- Verificar se a rota `/cep/<cep>` existe no backend

---

### Teste 5: Validação de campos obrigatórios

**Passo 1: Tentar cadastro sem nome**
1. Abrir cadastro
2. Deixar nome vazio
3. Clicar "Continuar"

**Resultado esperado:** ❌ Erro "Preencha o nome completo"

**Passo 2: Tentar cadastro sem email**
1. Preencher nome
2. Deixar email vazio
3. Clicar "Continuar"

**Resultado esperado:** ❌ Erro "Digite um email válido"

---

## 🐛 DEBUG NO BACKEND

### 1. Ver logs de erro

**Terminal onde backend está rodando:**
```
[2026-08-24 10:30:45] [INFO] Banco de dados inicializado.
[2026-08-24 10:31:12] [INFO] POST /pacientes/ - 201 Created
[2026-08-24 10:31:45] [ERROR] Erro interno: list index out of range
```

### 2. Testar rotas com Postman/cURL

**Cadastro de paciente:**
```bash
curl -X POST http://127.0.0.1:5000/pacientes/ \
  -H "Content-Type: application/json" \
  -d '{"nome":"João","email":"joao@teste.com","senha":"123456"}'
```

**Esperado:**
```json
{
  "id": 1,
  "nome": "João",
  "email": "joao@teste.com",
  "telefone": null,
  ...
}
```

**Login:**
```bash
curl -X POST http://127.0.0.1:5000/pacientes/login \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@teste.com","senha":"123456"}'
```

**Esperado:**
```json
{
  "token": "eyJ0eXAi...",
  "paciente": {
    "id": 1,
    "nome": "João",
    ...
  }
}
```

**Listar clínicas (com JWT):**
```bash
curl -X GET http://127.0.0.1:5000/clinicas/ \
  -H "Authorization: Bearer eyJ0eXAi..."
```

### 3. Inspecionar banco de dados

**Instalar SQLite Browser:** https://sqlitebrowser.org/

**Abrir arquivo:**
```
backend/database/odonto.db
```

**Verificar se dados foram criados:**
- Tabela `paciente` → suas contas criadas
- Tabela `agendamento` → seus agendamentos
- Tabela `clinica` → clínicas cadastradas

---

## 🐛 DEBUG NO FRONTEND

### 1. Ver logs do Flutter

**Terminal onde `flutter run` está rodando:**
```
I/flutter (12345): Login bem-sucedido
I/flutter (12345): Token salvo: eyJ0eXAi...
E/flutter (12345): ❌ Erro de conexão com servidor
```

### 2. Habilitar modo debug

**Em `main.dart`:**
```dart
// Adicionar no início
import 'dart:developer' as developer;

// Na função _fazerLogin()
developer.log('Login iniciado: $email');
developer.log('Resposta do servidor: ${resultado.erro}');
```

### 3. Verificar SharedPreferences

**Não há ferramenta visual, mas pode debugar assim:**

**Em `sessao_usuario.dart`:**
```dart
static Future<bool> carregar() async {
  final prefs = await SharedPreferences.getInstance();
  
  // ✅ Adicionar debug
  print('=== SharedPreferences ===');
  print('Token: ${prefs.getString("token")}');
  print('ID: ${prefs.getInt("paciente_id")}');
  print('Nome: ${prefs.getString("paciente_nome")}');
  print('=======================');
  
  // ... resto do código
}
```

### 4. Testar API direto no app

**Adicionar botão temporário de teste em `main.dart`:**
```dart
import 'package:reodonto/services/api_service.dart';

// Em um botão qualquer
ElevatedButton(
  onPressed: () async {
    final resultado = await ApiService.buscarCep('30150380');
    print('Resultado: ${resultado.dados}');
    print('Erro: ${resultado.erro}');
  },
  child: const Text('Testar CEP'),
),
```

---

## 🚨 PROBLEMAS COMUNS E SOLUÇÕES

### ❌ "Sem conexão com o servidor. Verifique se o backend está rodando."

**Causas possíveis:**
1. Backend não está rodando
2. Porta 5000 já está em uso
3. Emulador não consegue acessar `10.0.2.2`

**Solução:**
```bash
# 1. Verificar se backend está rodando
netstat -an | findstr :5000  # Windows

# 2. Se estiver, matar e reiniciar
taskkill /PID <PID> /F
python app.py

# 3. Verificar URL no ApiService
# android: http://10.0.2.2:5000
# web: http://127.0.0.1:5000
# fisico: http://<seu-ip-local>:5000
```

---

### ❌ "Email já cadastrado"

**Causa:** Email já existe no banco

**Solução:**
```bash
# 1. Usar email diferente
# 2. OU limpar banco:
rm backend/database/odonto.db
python app.py  # Recriar tabelas
```

---

### ❌ "CEP não encontrado"

**Causa:** CEP inválido ou API BrasilAPI offline

**Teste:**
```bash
# Testar direto com cURL
curl https://brasilapi.com.br/api/cep/v2/30150380
```

**Se funcionar:**
- Problema é no frontend
- Verificar se CEP está sendo enviado corretamente

---

### ❌ "Token inválido" ao tentar agendar

**Causa:** Token expirado ou não foi enviado

**Solução:**
```dart
// Em api_service.dart, verificar _headersAuth
Map<String, String> get _headersAuth {
  final token = SessaoUsuario.token;
  print('Token sendo enviado: $token');  // ✅ Debug
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
```

---

### ❌ App fecha/crasheia ao abrir

**Solução:**
1. Ver logs do Flutter
2. Procurar por "Exception"
3. Adicionar try-catch em `main()` e `initState()`

```dart
@override
void initState() {
  super.initState();
  try {
    _carregarDados();
  } catch (e) {
    print('Erro em initState: $e');
  }
}
```

---

## ✅ CHECKLIST DE TESTE COMPLETO

### Antes de subir para produção:

- [ ] Login funciona
- [ ] Cadastro funciona
- [ ] CEP preenche automático
- [ ] Perfil edita
- [ ] Agendamentos carregam
- [ ] Logout funciona
- [ ] Session persiste ao reabrir
- [ ] Validações funcionam (CPF, email, CEP)
- [ ] Tratamento de erro (sem internet, servidor offline)
- [ ] Sem crashes
- [ ] Sem logs de erro vermelho (❌ CRITICAL)

---

## 📊 TABELA DE STATUS DE API

| Rota | Método | JWT? | Status | Testado? |
|------|--------|------|--------|----------|
| `/pacientes/` | POST | ❌ | ✅ 201 | ✅ |
| `/pacientes/login` | POST | ❌ | ✅ 200 | ✅ |
| `/pacientes/<id>` | GET | ✅ | ✅ 200 | ❓ |
| `/pacientes/<id>` | PUT | ✅ | ✅ 200 | ❓ |
| `/pacientes/<id>` | DELETE | ✅ | ✅ 204 | ❓ |
| `/cep/<cep>` | GET | ❌ | ✅ 200 | ✅ |
| `/clinicas/` | GET | ✅ | ✅ 200 | ❓ |
| `/dentistas/` | GET | ✅ | ✅ 200 | ❓ |
| `/consultas/` | GET | ✅ | ✅ 200 | ❓ |
| `/agendamentos/` | POST | ✅ | ✅ 201 | ❓ |
| `/agendamentos/` | GET | ✅ | ✅ 200 | ❓ |

---

## 🧠 DICAS DE DEBUG

### 1. Print com contexto
```dart
print('===== DEBUG: Buscando CEP =====');
print('CEP: $cep');
print('URL: $url');
print('Response: $response');
print('===== FIM DEBUG =====');
```

### 2. Adicionar timestamps
```dart
final agora = DateTime.now();
print('[$agora] Iniciando login...');
```

### 3. Testar com dados mock
```dart
// Ao invés de chamar a API, retornar dados fake para testar UI
if (kDebugMode) {
  // Retornar dados mock
  return ApiResultado.sucesso({
    'id': 1,
    'nome': 'João Mock',
  });
}
```

### 4. Adicionar breakpoints (VS Code)
```
F5 ou F9 no editor → coloca breakpoint
Executar com: flutter run
```

---

## 📈 PERFORMANCE

### Medir tempo de requisição
```dart
final inicio = DateTime.now();
final resultado = await ApiService.login(email: email, senha: senha);
final duracao = DateTime.now().difference(inicio);
print('Login levou: $duracao');
```

**Esperado:** < 2 segundos

---

## 📝 RELATÓRIO DE BUG

Se encontrar um bug, document assim:

**Título:** App crash ao abrir perfil

**Passos para reproduzir:**
1. Fazer login
2. Clicar "Perfil"
3. Esperar carregar

**Resultado esperado:**
- Dados do usuário aparecem

**Resultado atual:**
- App fecha com erro

**Erro (log completo):**
```
E/flutter (12345): Exception: list index out of range
E/flutter (12345): at Object.noSuchMethodError...
```

**Dispositivo:** Android Emulator Pixel 4 API 30

**Versão Flutter:** 3.13.0

---

**Última atualização:** 24/08/2026
