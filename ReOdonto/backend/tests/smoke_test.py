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

print('\n' + '=' * 60)
if falhas:
    print(f'{len(falhas)} FALHA(S):')
    for f in falhas:
        print('  -', f)
    sys.exit(1)
print('Todos os testes passaram.')
