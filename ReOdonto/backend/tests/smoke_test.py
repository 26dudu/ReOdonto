"""
Teste de fumaça dos fluxos principais do backend ReOdonto.

Roda contra um banco SQLite temporário — não toca no odonto.db — e simula
o envio de email e as respostas do Google. Execute de dentro de backend/:

    python tests/smoke_test.py
"""
import os
import sys
import tempfile
from datetime import datetime, timedelta

BACKEND = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BACKEND)
os.chdir(BACKEND)

banco = os.path.join(tempfile.mkdtemp(), 'teste.db')
os.environ['DATABASE_URL'] = f'sqlite:///{banco}'
os.environ['TESTING'] = 'true'
os.environ['JWT_SECRET_KEY'] = 'chave-de-teste-jwt'
os.environ['SECRET_KEY'] = 'chave-de-teste-flask'
os.environ['ENCRYPTION_KEY'] = 'chave-de-teste-para-criptografia'
os.environ['GOOGLE_CLIENT_ID'] = 'id-do-app.apps.googleusercontent.com'
os.environ['GOOGLE_CLIENT_SECRET'] = 'segredo-de-teste'

import app as app_module  # noqa: E402
from services import email_service  # noqa: E402

app = app_module.app
app.config['TESTING'] = True
cliente = app.test_client()

# Captura o código OTP em vez de enviar email.
codigos = {}
email_service.enviar_codigo = lambda destino, codigo: codigos.__setitem__(destino, codigo)
import services.recuperacao_service as rec  # noqa: E402
rec.email_service = email_service

falhas = []


def checar(descricao, condicao, detalhe=''):
    marca = 'ok  ' if condicao else 'FALHA'
    print(f'[{marca}] {descricao}' + (f' — {detalhe}' if detalhe and not condicao else ''))
    if not condicao:
        falhas.append(descricao)


def auth(token):
    return {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}


ontem = (datetime.now() - timedelta(days=1)).replace(microsecond=0)
as_14 = ontem.replace(hour=14, minute=0, second=0).isoformat()
as_1415 = ontem.replace(hour=14, minute=15, second=0).isoformat()
as_16 = ontem.replace(hour=16, minute=0, second=0).isoformat()

print('\n--- Cadastro e login ---')
r = cliente.post('/dentistas/', json={
    'nome': 'Dra. Ana', 'email': 'Ana@Clinica.com', 'senha': 'SenhaForte1',
    'telefone': '31988887777', 'cro': 'MG-12345', 'cpf_cnpj': '52998224725',
})
checar('cadastro de dentista aceito', r.status_code == 201, r.get_data(as_text=True))
dentista_id = r.get_json()['id']

r = cliente.post('/dentistas/', json={
    'nome': 'Curto', 'email': 'curto@x.com', 'senha': 'abc123',
})
checar('senha com menos de 8 caracteres recusada', r.status_code == 400,
       r.get_data(as_text=True))

# Login com outra caixa de maiúsculas que o cadastro.
r = cliente.post('/dentistas/login', json={'email': 'ana@clinica.com', 'senha': 'SenhaForte1'})
checar('login ignora maiúsculas no email', r.status_code == 200, r.get_data(as_text=True))
token = r.get_json()['token']

print('\n--- Conflito de horário por duração ---')
r = cliente.post('/agendamentos/', json={
    'data_hora': as_14, 'nome_paciente': 'João Silva',
    'telefone_paciente': '31999990000', 'consulta_customizada': 'Limpeza',
    'duracao_minutos': 30, 'valor': 200.0,
}, headers=auth(token))
checar('agendamento criado', r.status_code == 201, r.get_data(as_text=True))
agendamento_id = r.get_json()['id']
checar('valor exposto como consulta_valor', r.get_json().get('consulta_valor') == 200.0)

r = cliente.post('/agendamentos/', json={
    'data_hora': as_1415, 'nome_paciente': 'Maria', 'duracao_minutos': 30,
}, headers=auth(token))
checar('sobreposição de 15 min recusada', r.status_code == 400, r.get_data(as_text=True))

r = cliente.post('/agendamentos/', json={
    'data_hora': as_16, 'nome_paciente': 'Carlos', 'duracao_minutos': 30, 'valor': 150.0,
}, headers=auth(token))
checar('horário sem sobreposição aceito', r.status_code == 201, r.get_data(as_text=True))
outro_id = r.get_json()['id']

print('\n--- Cancelar abre horário vago ---')
r = cliente.patch(f'/agendamentos/{agendamento_id}/status',
                  json={'status': 'cancelado'}, headers=auth(token))
checar('cancelamento aceito', r.status_code == 200, r.get_data(as_text=True))
liberado = r.get_json().get('horario_liberado')
checar('cancelamento devolve horário liberado', liberado is not None)
checar('horário liberado está vago', bool(liberado and liberado['vago']))
checar('horário liberado herda o valor', bool(liberado and liberado['valor'] == 200.0))
vago_id = liberado['id'] if liberado else None

r = cliente.get('/agendamentos/', headers=auth(token))
agenda = r.get_json()
ids = {a['id'] for a in agenda}
checar('cancelado sai da agenda', agendamento_id not in ids)
checar('horário vago aparece na agenda', vago_id in ids)

print('\n--- Encaixe no horário vago ---')
r = cliente.patch(f'/agendamentos/{vago_id}/paciente-rapido',
                  json={'nome': 'Dona Marta', 'telefone': '31977776666'},
                  headers=auth(token))
checar('encaixe aceito', r.status_code == 200, r.get_data(as_text=True))
checar('encaixe marcado', r.get_json().get('encaixe') is True)

r = cliente.patch(f'/agendamentos/{vago_id}/paciente-rapido',
                  json={'nome': 'Outro'}, headers=auth(token))
checar('encaixe em horário já ocupado recusado', r.status_code == 400,
       r.get_data(as_text=True))

print('\n--- Concluir atendimento ---')
r = cliente.patch(f'/agendamentos/{outro_id}/status',
                  json={'status': 'concluido'}, headers=auth(token))
checar('conclusão aceita', r.status_code == 200, r.get_data(as_text=True))
r = cliente.patch(f'/agendamentos/{outro_id}/status',
                  json={'status': 'cancelado'}, headers=auth(token))
checar('concluído não pode ser alterado', r.status_code == 400)

print('\n--- Painel ---')
r = cliente.get('/painel/resumo', headers=auth(token))
checar('painel responde', r.status_code == 200, r.get_data(as_text=True))
painel = r.get_json()
checar('prejuízo evitado soma o encaixe', painel['prejuizo_evitado'] == 200.0, str(painel))
checar('1 horário recuperado', painel['horarios_recuperados'] == 1, str(painel))
checar('1 paciente encaixado', painel['pacientes_encaixados'] == 1, str(painel))
checar('1 cancelamento no resumo', painel['resumo_3_meses']['cancelamentos'] == 1, str(painel))
checar('1 consulta realizada', painel['resumo_3_meses']['consultas_realizadas'] == 1, str(painel))
checar('gráfico com 6 meses', len(painel['desempenho']) == 6, str(painel['desempenho']))
checar('mês mais recente tem o valor', painel['desempenho'][-1]['valor'] == 200.0,
       str(painel['desempenho']))
checar('taxa de ocupação entre 0 e 100',
       0 <= painel['resumo_3_meses']['taxa_ocupacao'] <= 100)

print('\n--- Autorização: paciente não age como dentista ---')
r = cliente.post('/pacientes/', json={
    'nome': 'Invasor', 'email': 'invasor@x.com', 'senha': 'SenhaForte1',
})
checar('cadastro de paciente aceito', r.status_code == 201, r.get_data(as_text=True))
paciente_id = r.get_json()['id']
checar('paciente tem o mesmo id do dentista (cenário da falha)',
       paciente_id == dentista_id, f'paciente={paciente_id} dentista={dentista_id}')

r = cliente.post('/pacientes/login', json={'email': 'invasor@x.com', 'senha': 'SenhaForte1'})
checar('login de paciente aceito', r.status_code == 200, r.get_data(as_text=True))
token_paciente = r.get_json()['token']

r = cliente.get('/agendamentos/', headers=auth(token_paciente))
checar('paciente NÃO lê a agenda do dentista', r.status_code == 403,
       f'status={r.status_code} body={r.get_data(as_text=True)}')
r = cliente.patch(f'/agendamentos/{outro_id}/status',
                  json={'status': 'cancelado'}, headers=auth(token_paciente))
checar('paciente NÃO cancela agendamento', r.status_code == 403, r.get_data(as_text=True))
r = cliente.get('/painel/resumo', headers=auth(token_paciente))
checar('paciente NÃO vê o painel', r.status_code == 403, r.get_data(as_text=True))
r = cliente.post('/clinicas/', json={'nome': 'Fake'}, headers=auth(token_paciente))
checar('paciente NÃO cria clínica', r.status_code == 403, r.get_data(as_text=True))

print('\n--- Autorização: dentista não mexe em outro dentista ---')
r = cliente.post('/dentistas/', json={
    'nome': 'Dr. Bruno', 'email': 'bruno@clinica.com', 'senha': 'SenhaForte2',
})
outro_dentista_id = r.get_json()['id']
r = cliente.post('/dentistas/login', json={'email': 'bruno@clinica.com', 'senha': 'SenhaForte2'})
token_bruno = r.get_json()['token']

r = cliente.put(f'/dentistas/{dentista_id}', json={'nome': 'Hackeado'},
                headers=auth(token_bruno))
checar('dentista NÃO edita outro dentista', r.status_code == 403, r.get_data(as_text=True))
r = cliente.delete(f'/dentistas/{dentista_id}', headers=auth(token_bruno))
checar('dentista NÃO apaga outro dentista', r.status_code == 403, r.get_data(as_text=True))
r = cliente.get(f'/dentistas/{dentista_id}', headers=auth(token_bruno))
checar('dentista NÃO lê o perfil de outro', r.status_code == 403, r.get_data(as_text=True))
r = cliente.get(f'/dentistas/{outro_dentista_id}', headers=auth(token_bruno))
checar('dentista lê o próprio perfil', r.status_code == 200, r.get_data(as_text=True))

print('\n--- Troca de senha exige a senha atual ---')
r = cliente.put(f'/dentistas/{outro_dentista_id}', json={'senha': 'NovaSenha123'},
                headers=auth(token_bruno))
checar('troca de senha sem a senha atual recusada', r.status_code == 400,
       r.get_data(as_text=True))
r = cliente.put(f'/dentistas/{outro_dentista_id}',
                json={'senha': 'NovaSenha123', 'senha_atual': 'SenhaForte2'},
                headers=auth(token_bruno))
checar('troca de senha com a senha atual aceita', r.status_code == 200,
       r.get_data(as_text=True))

print('\n--- Recuperação de senha do DENTISTA ---')
r = cliente.post('/dentistas/recuperar-senha', json={'email': 'ana@clinica.com'})
checar('dentista pede código de recuperação', r.status_code == 200, r.get_data(as_text=True))
codigo = codigos.get('Ana@Clinica.com')
checar('código gerado para o dentista', codigo is not None and len(codigo) == 6, str(codigos))

r = cliente.post('/dentistas/redefinir-senha', json={
    'email': 'ana@clinica.com', 'codigo': '000000', 'nova_senha': 'OutraSenha1',
})
checar('código errado recusado', r.status_code == 400, r.get_data(as_text=True))

r = cliente.post('/dentistas/redefinir-senha', json={
    'email': 'ana@clinica.com', 'codigo': codigo, 'nova_senha': 'OutraSenha1',
})
checar('senha do dentista redefinida', r.status_code == 200, r.get_data(as_text=True))
r = cliente.post('/dentistas/login', json={'email': 'ana@clinica.com', 'senha': 'OutraSenha1'})
checar('login com a nova senha funciona', r.status_code == 200, r.get_data(as_text=True))
r = cliente.post('/dentistas/redefinir-senha', json={
    'email': 'ana@clinica.com', 'codigo': codigo, 'nova_senha': 'TerceiraSenha1',
})
checar('código não pode ser reusado', r.status_code == 400, r.get_data(as_text=True))

print('\n--- Limite de pedidos por hora ---')
for _ in range(3):
    cliente.post('/dentistas/recuperar-senha', json={'email': 'bruno@clinica.com'})
r = cliente.post('/dentistas/recuperar-senha', json={'email': 'bruno@clinica.com'})
checar('limite por hora devolve 429', r.status_code == 429, r.get_data(as_text=True))
r = cliente.post('/dentistas/recuperar-senha', json={'email': 'naoexiste@x.com'})
checar('email inexistente devolve 404', r.status_code == 404, r.get_data(as_text=True))

print('\n--- Rotas /consultas registradas ---')
r = cliente.get('/consultas/', headers=auth(token_bruno))
checar('GET /consultas/ existe', r.status_code == 200, f'status={r.status_code}')
r = cliente.post('/consultas/', json={
    'nome': 'Limpeza', 'descricao': 'Profilaxia', 'valor': 200.0, 'duracao_minutos': 30,
}, headers=auth(token_bruno))
checar('POST /consultas/ cria tipo de consulta', r.status_code == 201,
       r.get_data(as_text=True))
r = cliente.post('/consultas/', json={'nome': 'X', 'descricao': 'Y', 'valor': 1},
                 headers=auth(token_paciente))
checar('paciente NÃO cria tipo de consulta', r.status_code == 403, r.get_data(as_text=True))

print('\n--- Apagar dentista com agendamentos ---')
r = cliente.delete(f'/dentistas/{outro_dentista_id}', headers=auth(token_bruno))
checar('dentista sem agendamentos é apagado', r.status_code == 204, r.get_data(as_text=True))

r = cliente.post('/dentistas/login', json={'email': 'ana@clinica.com', 'senha': 'OutraSenha1'})
token_ana = r.get_json()['token']
r = cliente.delete(f'/dentistas/{dentista_id}', headers=auth(token_ana))
checar('dentista COM agendamentos é apagado (cascade)', r.status_code == 204,
       r.get_data(as_text=True))

print('\n--- Login Google ---')
import controllers.google_auth_controller as gac  # noqa: E402


class _Resposta:
    def __init__(self, status, dados):
        self.status_code = status
        self._dados = dados
        self.text = str(dados)

    def json(self):
        return self._dados


def _falso_google(aud):
    def get(url, params=None, headers=None, timeout=None):
        if 'tokeninfo' in url:
            return _Resposta(200, {'aud': aud, 'email': 'nova@clinica.com',
                                   'email_verified': 'true'})
        return _Resposta(200, {'email': 'nova@clinica.com', 'name': 'Dra. Nova',
                               'verified_email': True})
    return get


gac.requests.get = _falso_google('id-de-OUTRO-app.apps.googleusercontent.com')
r = cliente.post('/auth/google/verify-token', json={'access_token': 'token-roubado'})
checar('access token de outro app recusado', r.status_code == 401, r.get_data(as_text=True))

gac.requests.get = _falso_google('id-do-app.apps.googleusercontent.com')
r = cliente.post('/auth/google/verify-token', json={'access_token': 'token-valido'})
checar('access token do app aceito', r.status_code == 200, r.get_data(as_text=True))
corpo = r.get_json() or {}
checar('Google devolve conta de DENTISTA', 'dentista' in corpo and 'paciente' not in corpo,
       str(corpo))
r = cliente.get('/agendamentos/', headers=auth(corpo.get('token', '')))
checar('dentista do Google acessa a agenda', r.status_code == 200, r.get_data(as_text=True))
r = cliente.post('/auth/google/verify-token', json={'access_token': 'token-valido'})
checar('segundo login Google reusa a mesma conta',
       (r.get_json() or {}).get('dentista', {}).get('id') == corpo.get('dentista', {}).get('id'))

print('\n--- Agendamento por WhatsApp (n8n) ---')
os.environ['INTEGRACAO_API_KEY'] = 'chave-de-teste-integracao'
chave = {'X-API-Key': 'chave-de-teste-integracao'}
r = cliente.post('/dentistas/', json={
    'nome': 'Dr. Zé', 'email': 'ze@clinica.com', 'senha': 'SenhaForte1',
    'telefone': '31977776666', 'cro': 'MG-777', 'cpf_cnpj': '11144477735',
})
ze_id = r.get_json()['id']
r = cliente.post('/dentistas/login', json={'email': 'ze@clinica.com', 'senha': 'SenhaForte1'})
ze_token = r.get_json()['token']

amanha = (datetime.now() + timedelta(days=2)).replace(hour=10, minute=0, second=0, microsecond=0)
while amanha.weekday() >= 5:
    amanha += timedelta(days=1)
vago_dia = (datetime.now() + timedelta(days=3)).replace(hour=9, minute=0, second=0, microsecond=0)
vago_outro = (datetime.now() + timedelta(days=4)).replace(hour=15, minute=0, second=0, microsecond=0)


def pedido(**extra):
    corpo = {'dentista_id': ze_id, 'nome_paciente': 'Carla', 'telefone_paciente': '31966665555',
             'data_hora': amanha.isoformat(), 'consulta_customizada': 'Limpeza'}
    corpo.update(extra)
    return cliente.post('/integracoes/whatsapp/agendar', json=corpo, headers=chave)


r = cliente.post('/integracoes/whatsapp/agendar', json={})
checar('sem chave de API retorna 401', r.status_code == 401, r.get_data(as_text=True))
r = cliente.post('/integracoes/whatsapp/agendar', json={}, headers={'X-API-Key': 'errada'})
checar('chave errada retorna 401', r.status_code == 401)

chave_original = os.environ.pop('INTEGRACAO_API_KEY')
r = cliente.post('/integracoes/whatsapp/agendar', json={}, headers=chave)
checar('integração sem chave configurada retorna 503', r.status_code == 503)
os.environ['INTEGRACAO_API_KEY'] = chave_original

r = pedido(nome_paciente='')
checar('pedido sem nome devolve dados_incompletos',
       r.status_code == 200 and r.get_json()['status'] == 'dados_incompletos', r.get_data(as_text=True))

r = pedido(consulta_customizada='')
corpo = r.get_json()
checar('pedido sem tipo de atendimento pergunta o tipo',
       corpo['status'] == 'dados_incompletos' and 'consulta_customizada' in corpo['faltando']
       and 'tipo de atendimento' in corpo['mensagem'], r.get_data(as_text=True))

r = pedido(nome_paciente='', consulta_customizada='', data_hora='')
corpo = r.get_json()
checar('pedido sem nada pergunta nome, tipo e data juntos',
       sorted(corpo['faltando']) == ['consulta_customizada', 'data_hora', 'nome_paciente'],
       r.get_data(as_text=True))

r = pedido()
corpo = r.get_json()
checar('horário livre é confirmado', r.status_code == 200 and corpo['status'] == 'confirmado',
       r.get_data(as_text=True))
checar('confirmação traz mensagem pronta para o WhatsApp', 'confirmada' in corpo['mensagem'])

r = cliente.post('/agendamentos/', json={'data_hora': vago_dia.isoformat(), 'duracao_minutos': 30},
                 headers=auth(ze_token))
vago_id = r.get_json()['id']
cliente.post('/agendamentos/', json={'data_hora': vago_outro.isoformat(), 'duracao_minutos': 30},
             headers=auth(ze_token))

r = pedido(nome_paciente='Bruno', data_hora=vago_dia.isoformat())
checar('pedido no horário vago vira encaixe',
       r.status_code == 200 and r.get_json()['status'] == 'encaixado', r.get_data(as_text=True))
r = cliente.get('/agendamentos/', headers=auth(ze_token))
encaixado = [a for a in r.get_json() if a['id'] == vago_id]
checar('horário vago ficou marcado como encaixe com o paciente',
       bool(encaixado) and encaixado[0].get('encaixe') is True
       and encaixado[0].get('paciente_nome') == 'Bruno', str(encaixado))

r = pedido(nome_paciente='Diego')
corpo = r.get_json()
checar('horário ocupado devolve conflito com alternativas',
       r.status_code == 200 and corpo['status'] == 'conflito' and len(corpo['alternativas']) >= 1,
       r.get_data(as_text=True))
sugeridos = [datetime.fromisoformat(x['data_hora']) for x in corpo['alternativas']]
checar('sugere 3 horários livres sem sobrepor a consulta de 15 minutos',
       len(sugeridos) == 3 and all(abs((x - amanha).total_seconds()) >= 15 * 60 for x in sugeridos),
       str(sugeridos))
checar('o horário mais próximo sugerido é 15 minutos depois ou antes',
       min(abs((x - amanha).total_seconds()) for x in sugeridos) == 15 * 60, str(sugeridos))
r = pedido(nome_paciente='Eva', data_hora=(amanha + timedelta(minutes=10)).isoformat())
checar('pedido 10 minutos depois da consulta de 15 minutos é conflito',
       r.get_json()['status'] == 'conflito', r.get_data(as_text=True))
r = pedido(nome_paciente='Eva', data_hora=(amanha + timedelta(minutes=15)).isoformat())
checar('pedido 15 minutos depois é aceito', r.get_json()['status'] == 'confirmado',
       r.get_data(as_text=True))

r = pedido(data_hora=(datetime.now() - timedelta(days=1)).isoformat())
checar('data passada devolve data_invalida',
       r.status_code == 200 and r.get_json()['status'] == 'data_invalida')

r = pedido(dentista_id=999999)
checar('dentista inexistente retorna 400', r.status_code == 400)

print('\n--- Cancelamento por WhatsApp ---')


def cancelar(telefone, **extra):
    corpo = {'dentista_id': ze_id, 'telefone_paciente': telefone}
    corpo.update(extra)
    return cliente.post('/integracoes/whatsapp/cancelar', json=corpo, headers=chave)


r = cliente.post('/integracoes/whatsapp/cancelar', json={})
checar('cancelar sem chave de API retorna 401', r.status_code == 401)

r = cancelar('5531900000999')
checar('cancelar sem consulta devolve nao_encontrado',
       r.status_code == 200 and r.get_json()['status'] == 'nao_encontrado', r.get_data(as_text=True))

dia1 = amanha + timedelta(days=1)
while dia1.weekday() >= 5:
    dia1 += timedelta(days=1)
dia2 = dia1 + timedelta(days=1)
while dia2.weekday() >= 5:
    dia2 += timedelta(days=1)
tel = '5531977770001'
r = pedido(nome_paciente='Paula', telefone_paciente=tel, data_hora=dia1.isoformat())
checar('prepara a consulta da Paula', r.get_json()['status'] == 'confirmado', r.get_data(as_text=True))

r = cancelar('31 97777-0001')
corpo = r.get_json()
checar('cancela a única consulta do número, com telefone em outro formato',
       r.status_code == 200 and corpo['status'] == 'cancelado', r.get_data(as_text=True))
r = cliente.get('/agendamentos/', headers=auth(ze_token))
doutor = [a for a in r.get_json() if a['data_hora'].startswith(dia1.strftime('%Y-%m-%dT%H:%M'))]
checar('o horário cancelado vira horário vago na agenda',
       any(a.get('vago') for a in doutor) and not any(a.get('paciente_nome') == 'Paula' for a in doutor),
       str(doutor))

r = cancelar(tel)
checar('cancelar de novo devolve nao_encontrado', r.get_json()['status'] == 'nao_encontrado',
       r.get_data(as_text=True))

pedido(nome_paciente='Paula', telefone_paciente=tel, data_hora=dia1.isoformat())
pedido(nome_paciente='Paula', telefone_paciente=tel, data_hora=dia2.isoformat())
r = cancelar(tel)
corpo = r.get_json()
checar('com duas consultas, pergunta qual cancelar',
       corpo['status'] == 'escolher' and len(corpo['consultas']) == 2, r.get_data(as_text=True))

r = cancelar(tel, data_hora=dia2.isoformat())
checar('com duas consultas e a data informada, cancela a escolhida',
       r.get_json()['status'] == 'cancelado', r.get_data(as_text=True))
r = cancelar(tel)
checar('sobra só a outra consulta', r.get_json()['status'] == 'cancelado'
       and r.get_json()['agendamento']['data_hora'].startswith(dia1.strftime('%Y-%m-%d')),
       r.get_data(as_text=True))

r = cliente.post('/integracoes/whatsapp/cancelar', json={'dentista_id': ze_id}, headers=chave)
checar('cancelar sem telefone retorna 400', r.status_code == 400)


print('\n' + '=' * 60)
if falhas:
    print(f'{len(falhas)} FALHA(S):')
    for f in falhas:
        print('  -', f)
    sys.exit(1)
print('Todos os testes passaram.')
