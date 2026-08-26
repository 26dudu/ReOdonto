# 📋 CHECKLIST COMPLETO — ReOdonto

**Data:** 24/08/2026  
**Status:** Projeto em desenvolvimento funcional  
**Objetivo:** Sistema de agendamento odontológico (Flutter + Flask + SQLite)

---

## 📌 RESUMO EXECUTIVO

Seu projeto está **40% completo e funcional**. Backend com autenticação JWT, validações e banco de dados relacional está pronto. Frontend com login, cadastro e máscaras de entrada está em bom estado. 

**Próximas fases críticas:**
1. Integração completa de CEP (já iniciada)
2. Telas de agendamento (parcial)
3. Tela de perfil e edição
4. Testes e melhorias de UX/segurança

---

## ✅ O QUE JÁ ESTÁ FUNCIONANDO

### Backend ✔️

- ✅ **App Flask** com CORS, JWT e tratamento de erros globais
- ✅ **Banco SQLite** com 5 modelos (Paciente, Dentista, Clínica, Consulta, Agendamento)
- ✅ **Foreign Keys habilitadas** no SQLite
- ✅ **Autenticação JWT** com tokens de 8 horas
- ✅ **Rota de cadastro** `/pacientes/` com validação de email/CPF único
- ✅ **Rota de login** `/pacientes/login` com hash seguro de senha (bcrypt)
- ✅ **Rota de CEP** `/cep/<cep>` com integração BrasilAPI
- ✅ **Proteção com @jwt_required()** em todas as rotas sensíveis
- ✅ **Validação de FK explícita** antes de inserir agendamentos
- ✅ **Detecção de conflito de horário** (evita que dentista tenha 2 agendamentos na mesma hora)
- ✅ **Relacionamentos ORM** no modelo Agendamento (paciente, dentista, consulta, clínica)
- ✅ **Método to_dict_completo()** que retorna dados relacionados em uma chamada

### Frontend ✔️

- ✅ **Tela de Login** com validação básica e integração JWT
- ✅ **Tela de Cadastro** em 2 etapas (dados pessoais + senha)
- ✅ **Persistência de sessão** com SharedPreferences
- ✅ **ApiService** com tratamento de erro e detecção de 401 (sessão expirada)
- ✅ **Máscaras de entrada** (telefone, CPF, CEP) nos widgets
- ✅ **Estrutura de pastas** bem organizada (pages, services, widgets, theme, utils)
- ✅ **Responsividade** (celular e desktop com LayoutBuilder)
- ✅ **Indicador de etapa** na tela de cadastro
- ✅ **Loading state** com CircularProgressIndicator durante requisições

---

## ⚠️ PROBLEMAS ENCONTRADOS

### 🔴 CRÍTICOS

#### 1. **CEP Lookup — Rua e Bairro IMUTÁVEIS**
- **Problema:** A BrasilAPI retorna rua e bairro, mas você permitiu que eles sejam alterados
- **Risco:** Dados inconsistentes entre o que a API devolveu e o que está salvo
- **Status:** Parcialmente corrigido
- **O que fazer:**
  - ✅ Backend recebe `rua` e `bairro` fixos da API
  - ✅ Frontend bloqueia edição desses campos após CEP ser preenchido
  - ❌ Falta validação no backend para rejeitar rua/bairro diferentes da API

**Ação necessária:**
```python
# Em paciente_service.py — ao buscar CEP, validar que rua/bairro batem
```

#### 2. **Tela de Agendamento — VAZIA**
- **Problema:** `telaAgenda.dart` existe mas está vazia (22 KB de código inútil)
- **Impacto:** Usuário não consegue ver/criar agendamentos
- **O que fazer:**
  1. Implementar lista de agendamentos com filtro por status
  2. Adicionar botão "Novo Agendamento"
  3. Modal para selecionar dentista, consulta, clínica e data/hora
  4. Exibir detalhes completos com `to_dict_completo()`

#### 3. **Tela de Perfil — INCOMPLETA**
- **Problema:** `telaPerfil.dart` tem 17 KB mas falta edição de dados
- **Impacto:** Paciente não consegue atualizar telefone, CPF, endereço
- **O que fazer:**
  1. Adicionar rota PUT `/pacientes/<id>` (já existe no backend)
  2. Implementar formulário de edição com mesmas máscaras
  3. Botão de salvar com validação
  4. Botão de logout

#### 4. **Dados da BrasilAPI não são persistidos corretamente**
- **Problema:** `buscarCep()` no frontend retorna dados mas não preenche os TextEditingControllers
- **Status:** Parcial — o json é retornado mas os campos não são alimentados
- **O que fazer:**
  - Adicionar callback no widget de CEP para preencher rua/bairro automaticamente
  - Bloquear edição de rua/bairro após busca bem-sucedida

#### 5. **API_SERVICE — URL Base pode estar INCORRETA**
- **Problema:** `_baseUrl` usa `http://10.0.2.2:5000` para Android
- **Risco:** Se o backend não está rodando nesse endereço, tudo falha
- **Verificar:**
  - Backend está em `http://0.0.0.0:5000`?
  - Teste com `curl http://10.0.2.2:5000/pacientes/ -X POST`

---

### 🟠 IMPORTANTES

#### 6. **Sem rota de login com token já salvo**
- **Problema:** Se usuário fecha o app e abre de novo, precisa fazer login novamente
- **Solução recomendada:**
  ```dart
  // Em main.dart — após WidgetsFlutterBinding.ensureInitialized()
  bool temSessao = await SessaoUsuario.carregar();
  final tela = temSessao ? TelaHome() : TelaLogin();
  ```

#### 7. **Controllers de TextEdit vazios ao navegar**
- **Problema:** Se usuário vai para Cadastro e volta para Login, os campos permanecem preenchidos
- **Solução:** Limpar controllers no `dispose()` ou ao voltar

#### 8. **Sem validação de CPF (apenas máscara)**
- **Problema:** Máscara adiciona pontos mas não valida dígito verificador
- **Solução:** Adicionar função de validação de CPF real

#### 9. **Sem tradeamento de erro de conexão no login**
- **Problema:** Se backend não responde, mensagem é genérica
- **Melhoria:** Diferenciar "sem internet" de "servidor offline"

#### 10. **Rota `/pacientes/<id>` não é chamada**
- **Problema:** Existe no backend mas não há botão para ver perfil
- **Solução:** Implementar `ApiService.buscarPerfil(id)` e usar em `telaPerfil`

---

### 🟡 OBSERVAÇÕES

#### 11. **Todos os controllers controlam manualmente**
- **Problema:** Não há um State Manager (Provider, GetX, Riverpod)
- **Impacto:** App funciona mas fica complexo conforme cresce
- **Não é urgente:** mas considere usar GetX depois

#### 12. **Sem debounce na busca de CEP**
- **Problema:** Cada digito dispara uma requisição
- **Solução:** Adicionar delay de 500ms antes de fazer a chamada

#### 13. **Sem tratamento de concorrência**
- **Problema:** Se usuário clicar "Criar conta" 2x, duas contas são criadas
- **Solução:** Flag `_carregando` já existe mas necessita sincronização melhor

#### 14. **Logs do backend são INFO — falta DEBUG**
- **Problema:** Hard debugar problemas sem mais detalhes
- **Solução:** Adicionar `logger.debug()` em pontos críticos

#### 15. **Docker/Deployment não está configurado**
- **Problema:** Sem docker-compose, é difícil rodar em produção
- **Solução:** Criar Dockerfile + docker-compose.yml

---

## 📋 CHECKLIST DETALHADO DO BACKEND

### Models ✅
- [x] Paciente com campos corretos
- [x] Dentista com CRO
- [x] Clínica com endereço completo
- [x] Consulta com valor e duração
- [x] Agendamento com relacionamentos e to_dict_completo()
- [ ] **TODO:** Adicionar `created_at` e `updated_at` em todos os modelos
- [ ] **TODO:** Adicionar coluna `ativo` (soft delete)

### Services ✅
- [x] Paciente: criar, buscar, atualizar, deletar, listar
- [x] Dentista: criar, buscar, atualizar, deletar, listar
- [x] Clínica: criar, buscar, atualizar, deletar, listar com paginação
- [x] Consulta: criar, buscar, atualizar, deletar, listar
- [x] Agendamento: criar com validação de FK, listar com filtro, atualizar status
- [x] BrasilAPI CEP: buscar CEP e retornar dados formatados
- [ ] **TODO:** Adicionar serviço de Email (enviar confirmação de agendamento)
- [ ] **TODO:** Adicionar serviço de Notificação (lembretes)

### Controllers ✅
- [x] Paciente: cadastro, login, GET próprio perfil, PUT perfil, DELETE
- [x] Dentista: CRUD com JWT
- [x] Clínica: CRUD com paginação e JWT
- [x] Consulta: CRUD com JWT
- [x] Agendamento: POST, GET com filtro, PATCH status, DELETE
- [x] CEP: GET com tratamento de erro
- [ ] **TODO:** Adicionar rota GET `/dentistas/?clinica_id=X` (filtrar dentistas por clínica)
- [ ] **TODO:** Adicionar rota GET `/consultas/` (listar todas as consultas disponíveis)

### Validações ✅
- [x] Email único para Paciente e Dentista
- [x] CPF único para Paciente
- [x] Senha com hash bcrypt
- [x] CEP com 8 dígitos
- [x] Data/hora no futuro para agendamento
- [x] Conflito de horário (dentista não pode ter 2 agendamentos)
- [x] Validação de FK explícita
- [ ] **TODO:** Validar CPF pelo algoritmo (dígito verificador)
- [ ] **TODO:** Validar telefone (apenas números e -/()?)
- [ ] **TODO:** Validar CRO do dentista (formato)

### Segurança ✅
- [x] JWT obrigatório em rotas sensíveis
- [x] Paciente não consegue editar outro paciente
- [x] Paciente só vê seus agendamentos
- [x] Senha com bcrypt
- [x] CORS configurado
- [ ] **TODO:** Rate limiting (evitar brute force)
- [ ] **TODO:** Validar Content-Type em requisições
- [ ] **TODO:** Validar tamanho máximo de payload
- [ ] **TODO:** SQL injection — validar em queries custom (se houver)

### Erro Handling ✅
- [x] Tratamento global de 400, 401, 403, 404, 405, 500
- [x] Mensagens de erro em JSON
- [x] Logging de erros 500
- [ ] **TODO:** Retornar mensagens de erro mais específicas (validação detalhada)
- [ ] **TODO:** Implementar erro de rate limit (429)

### Database ✅
- [x] SQLite com FK habilitadas
- [x] Criação automática de tabelas
- [x] Relacionamentos ORM
- [ ] **TODO:** Migrations (alembic)
- [ ] **TODO:** Backup automático
- [ ] **TODO:** Índices em campos de busca (email, cpf)

### Testes ❌
- [ ] **TODO:** Testes unitários para services
- [ ] **TODO:** Testes de integração para controllers
- [ ] **TODO:** Testes de autenticação
- [ ] **TODO:** Teste de performance (agendamentos em massa)

---

## 📋 CHECKLIST DETALHADO DO FRONTEND

### Tela de Login ✅
- [x] Email e senha obrigatórios
- [x] Validação de email básica
- [x] Toggle de visibilidade de senha
- [x] Integração com API `/pacientes/login`
- [x] Salvar token e dados em SharedPreferences
- [x] Exibir erro em SnackBar
- [x] Loading state durante requisição
- [x] Link "Esqueci minha senha" (placeholder)
- [x] Link "Cadastre-se"
- [ ] **TODO:** Botão "Google Login" (integração com Firebase)
- [ ] **TODO:** Recuperação de senha real

### Tela de Cadastro ✅
- [x] Tela 1: Dados pessoais (nome, email, telefone, CPF, CEP, rua, bairro, número)
- [x] Tela 2: Senha (senha, confirmar senha)
- [x] Máscaras de entrada (telefone, CPF, CEP)
- [x] Indicador de etapa
- [x] Navegação entre etapas
- [x] Integração com BrasilAPI para CEP
- [x] Validação de campos obrigatórios
- [x] Loading state
- [x] Responsivo (celular e desktop)
- [ ] **TODO:** Preenchimento automático de rua/bairro após CEP
- [ ] **TODO:** Bloquear edição de rua/bairro após CEP ser preenchido
- [ ] **TODO:** Validação de CPF real
- [ ] **TODO:** Botão "Google Signup"
- [ ] **TODO:** Termos de serviço (checkbox)

### Tela de Perfil ⚠️
- [x] Estrutura básica existe
- [ ] **TODO:** Exibir dados do paciente logado
- [ ] **TODO:** Editar nome, email, telefone, CPF, endereço
- [ ] **TODO:** Rota PUT `/pacientes/<id>` com validação
- [ ] **TODO:** Botão de salvar com loading
- [ ] **TODO:** Botão de deletar conta (com confirmação)
- [ ] **TODO:** Botão de logout
- [ ] **TODO:** Link para histórico de agendamentos
- [ ] **TODO:** Exibir data de criação da conta

### Tela de Agendamento ❌
- [ ] **TODO:** Listar agendamentos do paciente
- [ ] **TODO:** Filtro por status (agendado, concluído, cancelado)
- [ ] **TODO:** Exibir detalhes: dentista, clínica, consulta, data, hora
- [ ] **TODO:** Botão "Novo Agendamento"
- [ ] **TODO:** Modal: selecionar clínica
- [ ] **TODO:** Modal: selecionar dentista (filtrado por clínica)
- [ ] **TODO:** Modal: selecionar tipo de consulta
- [ ] **TODO:** Modal: picker de data/hora
- [ ] **TODO:** Botão de cancelar agendamento
- [ ] **TODO:** Exibir mensagem quando não há agendamentos

### Tela de Menu ❌
- [ ] **TODO:** Implementar menu sanduíche ou drawer
- [ ] **TODO:** Links para: Perfil, Agendamentos, Sobre, Logout
- [ ] **TODO:** Avatar e nome do usuário
- [ ] **TODO:** Ícones representativos

### Tela de Alertas ❌
- [ ] **TODO:** Notificações de confirmação de agendamento
- [ ] **TODO:** Notificações de cancelamento
- [ ] **TODO:** Notificações de lembretes

### ApiService ✅
- [x] Cadastro de paciente
- [x] Login de paciente
- [x] Busca de CEP
- [x] Listar clínicas com paginação
- [x] Listar agendamentos
- [x] Criar agendamento
- [x] Cancelar agendamento
- [x] Tratamento de erro e timeout
- [x] Headers com JWT
- [ ] **TODO:** Buscar perfil GET `/pacientes/<id>`
- [ ] **TODO:** Atualizar perfil PUT `/pacientes/<id>`
- [ ] **TODO:** Deletar conta DELETE `/pacientes/<id>`
- [ ] **TODO:** Listar dentistas GET `/dentistas/`
- [ ] **TODO:** Listar consultas GET `/consultas/`

### SessaoUsuario ✅
- [x] Salvar token e dados após login
- [x] Carregar sessão salva ao abrir app
- [x] Limpar sessão no logout
- [x] Propriedade `estaLogado`
- [ ] **TODO:** Validar se token não está expirado

### Widgets ✅
- [x] CabecalhoCadastro
- [x] InfoBasicas
- [x] LocalizacaoClinica (com máscara de CEP)
- [x] Senha
- [ ] **TODO:** Widget de clínica (card com nome, endereço, telefone)
- [ ] **TODO:** Widget de agendamento (card com dentista, consulta, data, hora)
- [ ] **TODO:** Widget de filtro de status

### Theme ✅
- [x] Cores definidas em `AppColors`
- [x] Aplicadas no MaterialApp
- [ ] **TODO:** Adicionar fontes customizadas
- [ ] **TODO:** Modo escuro (dark mode)

### Utils ❌
- [ ] **TODO:** Funções de formatação (data, hora, moeda)
- [ ] **TODO:** Funções de validação (email, CPF, telefone, CEP)
- [ ] **TODO:** Funções de máscara (aplicar em um lugar central)
- [ ] **TODO:** Constantes de rotas e URLs

### Dependências ✅
- [x] flutter
- [x] cupertino_icons
- [x] device_preview
- [x] sign_in_button
- [x] flutter_svg
- [x] http
- [x] shared_preferences
- [ ] **TODO:** firebase_auth (para Google Login)
- [ ] **TODO:** intl (para formatação de data/hora)
- [ ] **TODO:** mask_text_input_formatter (para máscaras centralizadas)

### Testes ❌
- [ ] **TODO:** Testes de widget
- [ ] **TODO:** Testes de integração (e2e)
- [ ] **TODO:** Teste de login
- [ ] **TODO:** Teste de cadastro

---

## 🚀 PRIORIDADES IMEDIATAS (MVP)

### P0 — Crítico (faça hoje)
1. **Preencher automático de rua/bairro após busca de CEP**
   - Arquivo: `telaCadastro.dart` → `AddressInfoFields`
   - Tempo: 15 min

2. **Implementar tela de agendamento (básica)**
   - Arquivo: `telaAgenda.dart`
   - Funcionalidade: listar agendamentos do paciente
   - Tempo: 1 hora

3. **Testar login e cadastro no Flutter de verdade**
   - Rodar backend: `python app.py`
   - Rodar emulador: `flutter run`
   - Verificar se token é salvo e reutilizado

### P1 — Alta (faça amanhã)
1. **Implementar tela de perfil (edição)**
   - Arquivo: `telaPerfil.dart`
   - Funcionalidade: exibir dados, editar, logout
   - Tempo: 1.5 horas

2. **Adicionar validação de CPF real**
   - Função de validação no `utils/`
   - Aplicar em `AddressInfoFields`
   - Tempo: 30 min

3. **Implementar menu (drawer ou sanduíche)**
   - Arquivo: novo `telaMenu.dart`
   - Integrar em main.dart
   - Tempo: 1 hora

### P2 — Média (faça na semana)
1. **Criar modal de novo agendamento**
   - Seleção de clínica, dentista, consulta, data/hora
   - Validação de horário disponível
   - Tempo: 2 horas

2. **Implementar dados de dentistas e consultas**
   - GET `/dentistas/` no backend
   - GET `/consultas/` no backend
   - Integração no frontend
   - Tempo: 1 hora (backend) + 1 hora (frontend)

3. **Adicionar testes básicos**
   - Login test
   - Cadastro test
   - Tempo: 2 horas

---

## 🔧 PROBLEMAS POR ÁREA

### Backend — Segurança
- [ ] Rate limiting (evitar DDoS)
- [ ] Validar tamanho de payload
- [ ] HTTPS em produção (SSL/TLS)
- [ ] Secrets em variáveis de ambiente
- [ ] Roles de usuário (paciente, dentista, admin)

### Backend — Performance
- [ ] Índices no banco (email, cpf, cep)
- [ ] Cache de clínicas/dentistas/consultas
- [ ] Paginação em agendamentos
- [ ] Query optimization

### Frontend — UX
- [ ] Loading skeleton (antes de carregar listas)
- [ ] Pull-to-refresh
- [ ] Search/filtro de clínicas
- [ ] Compartilhar agendamento
- [ ] Impressão de agendamento

### Frontend — Offline
- [ ] Sincronizar dados quando voltar online
- [ ] Cache local de consultas/clínicas
- [ ] Fila de ações offline

### Infraestrutura
- [ ] Docker para backend
- [ ] Banco em produção (PostgreSQL, não SQLite)
- [ ] CI/CD (GitHub Actions)
- [ ] Monitoramento de erros (Sentry)
- [ ] Backup automático

---

## 📊 ROADMAP COMPLETO

```
SEMANA 1 (Atual)
├─ Preencher auto de CEP
├─ Tela de agendamento (listar)
├─ Tela de perfil (editar)
└─ Testes básicos

SEMANA 2
├─ Modal de novo agendamento
├─ GET /dentistas/ e /consultas/
├─ Menu drawer
└─ Validação de CPF real

SEMANA 3
├─ Notificações (confirmação, lembretes)
├─ Email (confirmação de agendamento)
├─ Pagamentos (integração de POS)
└─ Relatórios

SEMANA 4+
├─ Admin panel (gerenciar dentistas, clínicas)
├─ Painel do dentista (ver agendamentos)
├─ Suporte a múltiplas clínicas
└─ Produção (Docker, PostgreSQL, SSL)
```

---

## 📝 GUIA DE TESTES MANUAL

### Teste 1: Cadastro Completo
1. Abrir app
2. Clicar "Cadastre-se"
3. Preencher: Nome, Email, Telefone
4. Preencher CPF (teste: 123.456.789-10)
5. Preencher CEP (teste: 30150-380)
6. Verificar se rua/bairro foram preenchidos
7. Preencher número (teste: 123)
8. Clicar "Continuar"
9. Preencher: Senha, Confirmar Senha
10. Clicar "Criar conta"
11. Verificar se voltou para login
12. **RESULTADO ESPERADO:** Conta criada, pode fazer login com email/senha

### Teste 2: Login
1. Na tela de login, inserir email e senha criados
2. Clicar "Entrar"
3. Aguardar resposta
4. **RESULTADO ESPERADO:** Token salvo, app navega para próxima tela
5. Fechar app e abrir novamente
6. **RESULTADO ESPERADO:** App não pede login de novo (sessão persistida)

### Teste 3: CEP com valor inválido
1. Na tela de cadastro, inserir CEP inválido (ex: 12345)
2. Clicar fora do campo
3. **RESULTADO ESPERADO:** Mensagem de erro "CEP deve ter 8 dígitos"

### Teste 4: Dados duplicados
1. Tentar cadastrar com um email já existente
2. **RESULTADO ESPERADO:** Erro "Email já cadastrado"

### Teste 5: Agendamento (após implementar)
1. Fazer login
2. Ir para "Agendamentos"
3. Clicar "Novo Agendamento"
4. Selecionar clínica, dentista, consulta, data/hora
5. Clicar "Agendar"
6. **RESULTADO ESPERADO:** Agendamento criado, aparece na lista

---

## 🐛 BUGS CONHECIDOS

| ID | Severidade | Descrição | Status |
|----|-----------|-----------|--------|
| B001 | Crítica | CEP não preenche rua/bairro automaticamente | Não corrigido |
| B002 | Alta | Tela de agendamento vazia | Não corrigido |
| B003 | Alta | Tela de perfil não edita | Não corrigido |
| B004 | Média | Sem validação de CPF real | Não corrigido |
| B005 | Média | Sem session recovery ao abrir app | Não corrigido |
| B006 | Baixa | Sem debounce em CEP lookup | Não corrigido |

---

## ✨ MELHORIAS RECOMENDADAS

### Curto prazo (1-2 semanas)
- [ ] Adicionar loading skeleton
- [ ] Melhorar mensagens de erro
- [ ] Adicionar confirmação de ações (deletar, cancelar)
- [ ] Implementar pull-to-refresh em listas

### Médio prazo (1 mês)
- [ ] State Manager (GetX)
- [ ] Offline support
- [ ] Testes automatizados
- [ ] Dark mode

### Longo prazo (2+ meses)
- [ ] Painel admin
- [ ] Painel do dentista
- [ ] Pagamentos
- [ ] Múltiplas clínicas
- [ ] Produção (Docker, PostgreSQL)

---

## 📞 SUPORTE E PRÓXIMOS PASSOS

**Próxima ação:** Escolha o que quer fazer primeiro:
1. Preencher auto de CEP (rápido, impacto imediato)
2. Implementar tela de agendamento (mais trabalho, core feature)
3. Tela de perfil (essencial, 1-2 horas)

**Tempo total estimado até MVP completo:** 20-25 horas

---

**Documento gerado:** 24/08/2026  
**Análise de:** Sistema ReOdonto (Backend Flask + Frontend Flutter)
