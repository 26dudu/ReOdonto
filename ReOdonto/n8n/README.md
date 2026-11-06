# Agendamento automático por WhatsApp (n8n)

O paciente manda uma mensagem pedindo a consulta, o n8n entende o pedido com IA e chama a API do ReOdonto, que agenda sozinha e devolve a resposta pronta para o WhatsApp.

```
Paciente (WhatsApp) → Webhook n8n → IA extrai data e tipo → POST /integracoes/whatsapp/agendar → resposta ao paciente
```

## Resultados que a API devolve

| `status` | Quando acontece |
|---|---|
| `confirmado` | O horário estava livre e o agendamento foi criado |
| `encaixado` | O horário era um vago aberto por cancelamento e o paciente foi encaixado nele (conta como horário recuperado no painel) |
| `conflito` | O horário está ocupado; vêm até 3 `alternativas` com os próximos horários vagos |
| `data_invalida` | A data já passou |
| `dados_incompletos` | Faltou nome, data ou dentista |

A resposta sempre traz `mensagem`, um texto pronto para enviar ao paciente.

## Como rodar

1. Back-end: defina `INTEGRACAO_API_KEY` no `backend/.env` (modelo em `.env.example`) e rode `python app.py`.
2. Coloque `ANTHROPIC_API_KEY=sua-chave` no `backend/.env`.
3. Inicie o n8n com o script, que lê as chaves do `backend/.env` e configura as variáveis do workflow:

```bash
powershell -ExecutionPolicy Bypass -File n8n/iniciar_n8n.ps1
```

4. Abra http://localhost:5678, crie a conta do n8n na primeira vez e confira se o workflow "ReOdonto - Agendamento por WhatsApp" está publicado. Para importá-lo em outra máquina, use `workflow_whatsapp_agendamento.json`.
5. Simule uma mensagem de WhatsApp:

```bash
curl -X POST http://localhost:5678/webhook/whatsapp -H "Content-Type: application/json" -d "{\"mensagem\": \"Oi, queria marcar uma limpeza amanhã às 14h\", \"nome\": \"Maria\", \"telefone\": \"31999990000\"}"
```

## Ligando ao WhatsApp real

Troque o nó de entrada por um gatilho do WhatsApp Business (Cloud API da Meta) ou da Evolution API, e acrescente no fim um nó que envie o campo `resposta` de volta ao número do paciente.

## Testando só o back-end

A rota funciona sem o n8n:

```bash
curl -X POST http://127.0.0.1:5000/integracoes/whatsapp/agendar -H "X-API-Key: SUA_CHAVE" -H "Content-Type: application/json" -d "{\"dentista_id\": 1, \"nome_paciente\": \"Maria\", \"telefone_paciente\": \"31999990000\", \"data_hora\": \"2026-11-20T14:00:00\", \"consulta_customizada\": \"Limpeza\"}"
```
