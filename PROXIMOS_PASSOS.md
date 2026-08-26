# 🎯 PRÓXIMOS PASSOS IMEDIATOS

---

## 📊 STATUS ATUAL

**Seu projeto está 40% completo e funcional.**

```
Backend:        ████████░░ 80% (autenticação, BD, validações)
Frontend:       ██████░░░░ 60% (login, cadastro, básico)
Integração:     ███░░░░░░░ 30% (faltam telas principais)
Testes:         ░░░░░░░░░░  0% (nenhum teste automatizado)
Produção:       ░░░░░░░░░░  0% (sem Docker, sem DB externa)
═══════════════════════════════════════════════════════════
TOTAL:          ████░░░░░░ 40%
```

---

## 🚀 TAREFAS P0 (HOJE - 24/08)

### Tarefa P0-1: Testar o fluxo completo
**Tempo:** 20 min  
**Prioridade:** 🔴 CRÍTICA

**Fazer:**
1. Terminal 1: `cd backend && python app.py`
2. Terminal 2: `cd frontend && flutter run`
3. Registrar uma conta real
4. Fazer login
5. Verificar se sessão persiste ao fechar/reabrir

**Checklist:**
- [ ] Backend rodando sem erros
- [ ] App conecta ao backend
- [ ] Cadastro funciona
- [ ] Login funciona
- [ ] Sessão persiste
- [ ] Sem crashes

**Se tudo passar:** ✅ **PARABÉNS! Você tem um MVP funcional**

---

### Tarefa P0-2: Implementar preenchimento automático de CEP
**Tempo:** 30 min  
**Prioridade:** 🔴 CRÍTICA

**Arquivos a editar:**
- `frontend/lib/widgets/cadastro/localizacaaoClinica.dart`

**O que fazer:**
1. Abrir o arquivo `localizacaaoClinica.dart`
2. Procurar pelo método `_buscaCep()`
3. Adicionar: Após busca bem-sucedida, preencher `controladorRua` e `controladorBairro`
4. Bloquear edição desses campos (read-only)

**Solução pronta:** Ver `SOLUCOES_CRITICAS.md` → PROBLEMA 1

**Teste:**
1. Ir para cadastro
2. Preencher CEP: `30150380`
3. Clicar "Buscar"
4. ✅ Rua e bairro devem preencher e ficar cinzentos

---

### Tarefa P0-3: Implementar tela de agendamento (básica)
**Tempo:** 45 min  
**Prioridade:** 🔴 CRÍTICA

**Arquivos a editar:**
- `frontend/lib/pages/telaAgenda.dart`

**O que fazer:**
1. Abrir arquivo vazio `telaAgenda.dart`
2. Copiar código da solução em `SOLUCOES_CRITICAS.md` → PROBLEMA 2
3. Testar

**Teste:**
1. Fazer login
2. Ir para "Agendamentos"
3. ✅ Deve exibir "Você não tem agendamentos yet"
4. ✅ Deve ter botão "Agendar agora" (não funciona, apenas placeholder)

---

## 📅 TAREFAS P1 (SEMANA)

### Tarefa P1-1: Implementar tela de perfil
**Tempo:** 1 hora  
**Prioridade:** 🟠 ALTA

**Arquivos a editar:**
- `frontend/lib/pages/telaPerfil.dart`
- `frontend/lib/services/api_service.dart` (adicionar métodos)

**Solução pronta:** Ver `SOLUCOES_CRITICAS.md` → PROBLEMA 3

**Funcionalidades:**
- [ ] Exibir dados do paciente
- [ ] Editar nome, email, telefone
- [ ] Salvar alterações (PUT `/pacientes/<id>`)
- [ ] Botão de logout
- [ ] Botão de deletar conta

---

### Tarefa P1-2: Adicionar validação de CPF real
**Tempo:** 15 min  
**Prioridade:** 🟠 ALTA

**Arquivo novo:**
- `frontend/lib/utils/validadores.dart`

**Solução pronta:** Ver `SOLUCOES_CRITICAS.md` → PROBLEMA 4

**Teste:**
1. Tentar cadastro com CPF falso: `11111111111`
2. ✅ Erro: "CPF inválido"

---

### Tarefa P1-3: Criar menu drawer
**Tempo:** 45 min  
**Prioridade:** 🟠 ALTA

**Arquivo novo:**
- `frontend/lib/pages/telaMenu.dart` (ou implementar em main.dart)

**Links no menu:**
- Home (dashboard - placeholder)
- Agendamentos
- Perfil
- Sobre
- Logout

---

### Tarefa P1-4: Session recovery (auto-login)
**Tempo:** 15 min  
**Prioridade:** 🟠 ALTA

**Arquivo a editar:**
- `frontend/lib/main.dart`

**O que fazer:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ ADICIONAR ISSO
  bool temSessao = await SessaoUsuario.carregar();
  
  runApp(MeuApp(temSessao: temSessao));
}

class MeuApp extends StatelessWidget {
  final bool temSessao;
  
  // ...
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      home: temSessao ? TelaPerfil() : TelaLogin(),  // ✅ MUDAR ISSO
    );
  }
}
```

**Teste:**
1. Fazer login
2. Fechar app
3. Reabrir app
4. ✅ Não deve pedir login de novo

---

## 🔧 TAREFAS P2 (2 SEMANAS)

### Tarefa P2-1: Modal de novo agendamento
**Tempo:** 2 horas  
**Prioridade:** 🟡 MÉDIA

**Funcionalidades:**
- [ ] Selecionar clínica
- [ ] Selecionar dentista (filtrado por clínica)
- [ ] Selecionar tipo de consulta
- [ ] Picker de data/hora
- [ ] Botão "Agendar"

### Tarefa P2-2: Endpoints para dentistas e consultas
**Tempo:** 1 hora (backend) + 30 min (frontend)  
**Prioridade:** 🟡 MÉDIA

**Backend:**
- [ ] GET `/dentistas/` (listar todos)
- [ ] GET `/dentistas/?clinica_id=X` (filtrar por clínica)
- [ ] GET `/consultas/` (listar todas)

**Frontend:**
- [ ] ApiService.listarDentistas()
- [ ] ApiService.listarConsultas()

### Tarefa P2-3: Testes automatizados
**Tempo:** 2 horas  
**Prioridade:** 🟡 MÉDIA

**Backend:**
- [ ] Testes unitários para services
- [ ] Testes de integração para controllers

**Frontend:**
- [ ] Testes de widget para login
- [ ] Testes de widget para cadastro

---

## 📊 ROADMAP VISUAL

```
HOJE (24/08)
├─ P0-1: Testar fluxo completo
├─ P0-2: CEP automático
└─ P0-3: Tela de agendamentos

SEMANA 1 (25-28/08)
├─ P1-1: Tela de perfil
├─ P1-2: Validação CPF
├─ P1-3: Menu drawer
└─ P1-4: Session recovery

SEMANA 2 (29/08-04/09)
├─ P2-1: Modal agendamento
├─ P2-2: APIs dentista/consulta
└─ P2-3: Testes

SEMANA 3+ (05/09+)
├─ Notificações
├─ Email
├─ Pagamentos
└─ Admin panel
```

---

## 💡 DICAS IMPORTANTES

### 1. **Antes de começar uma tarefa**
```
□ Ler o arquivo da tarefa
□ Entender o que precisa mudar
□ Fazer backup/commit git
□ Fazer a mudança
□ Testar
□ Commit com mensagem clara
```

### 2. **Mensagens de commit**
```
git add .
git commit -m "feat: implementar preenchimento automático de CEP"
git commit -m "fix: corrigir validação de sessão"
git commit -m "refactor: reorganizar imports"
```

### 3. **Se algo der errado**
```bash
# Voltar para versão anterior
git status
git diff  # Ver mudanças
git checkout -- arquivo.dart  # Desfazer mudanças
```

### 4. **Debug rápido**
```dart
// Adicionar em qualquer lugar
print('🔍 DEBUG: $variavel');

// Flutter rebuild rápido
R + Enter (emulador rodando)
```

---

## ✅ CHECKLIST PARA CADA TAREFA

Ao terminar uma tarefa, verificar:

```
Funcionalidade:
- [ ] Código escrito
- [ ] App não crasheia
- [ ] Sem erros de compilação
- [ ] Sem logs vermelhos

Teste Manual:
- [ ] Cenário 1: happy path ✅
- [ ] Cenário 2: erro esperado ✅
- [ ] Cenário 3: dados vazios ✅

Código:
- [ ] Sem console.log/print deixado
- [ ] Variáveis com nome claro
- [ ] Sem código duplicado
- [ ] Formatação (Ctrl+Alt+L)

Git:
- [ ] Commit feito
- [ ] Mensagem descritiva
- [ ] Branch correto
```

---

## 🎓 APRENDER ENQUANTO FAZIO

### Para melhorar Flutter
- Estado management: GetX, Provider, Riverpod
- Animations: AnimatedBuilder, Tween
- Forms: validation, auto-complete

### Para melhorar Backend
- Migrations: Alembic
- Caching: Redis
- Background jobs: Celery
- Testing: pytest, hypothesis

---

## 📞 QUANDO PEDIR AJUDA

Se ficar travado:

1. **Erro de compilação:**
   - Copiar erro completo
   - Colar no chat
   - Descrever o contexto

2. **App não funciona:**
   - Abrir DevTools (F12)
   - Ver console/network
   - Descrever o que esperava vs recebeu

3. **Não sabe por onde começar:**
   - Reler a tarefa
   - Ver o arquivo de soluções
   - Fazer um passo de cada vez

---

## 🏁 OBJETIVO FINAL

**Até 01/09 (1 semana):**
- ✅ Cadastro funcional
- ✅ Login com sessão persistida
- ✅ Perfil editável
- ✅ Listagem de agendamentos
- ✅ CEP automático
- ✅ Validações corretas
- ✅ Menu de navegação

**MVP Completo:** Paciente consegue se registrar, fazer login, editar perfil, listar agendamentos e buscar endereço por CEP.

---

## 📈 MÉTRICAS DE SUCESSO

| Métrica | Atual | Objetivo |
|---------|-------|----------|
| Funcionalidades | 40% | 70% |
| Bugs conhecidos | 6 | 0 |
| Testes | 0 | 10+ |
| Tempo até MVP | - | 1 semana |
| Usuários testes | 0 | 5+ |

---

## 🎯 Resumo: O que fazer AGORA

1. **Termine as 3 tarefas P0:**
   - Testar fluxo
   - CEP automático
   - Tela agendamentos

2. **Tempo total:** ~1.5 horas

3. **Resultado:** MVP básico funcional

4. **Próximo:** Semana que vem, continue com P1

---

**Boa sorte! 🚀**

*Última atualização: 24/08/2026*
