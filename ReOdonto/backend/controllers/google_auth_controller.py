"""
Autenticação Google OAuth2 para ReOdonto.

Fluxo:
1. Frontend solicita login Google → /auth/google/login
2. Backend redireciona para Google → usuario faz login/autoriza
3. Google redireciona para /auth/google/callback com código
4. Backend troca código por token Google
5. Backend obtém user_info do Google
6. Backend encontra (ou cria) o DENTISTA com esse email
7. Backend retorna JWT + dados do dentista, no mesmo formato de /dentistas/login

Antes este fluxo criava um paciente. Como o app é do dentista e as rotas da
agenda exigem token de dentista, quem entrava pelo Google não via nada.

SETUP NO GOOGLE CONSOLE:
1. Vá para https://console.cloud.google.com
2. Crie um novo projeto
3. Ative a API "Google+ API"
4. Crie credenciais OAuth 2.0 (tipo: Web application)
   - URIs autorizados: http://localhost:5000
   - URIs de redirecionamento autorizados: http://localhost:5000/auth/google/callback
5. Coloque GOOGLE_CLIENT_ID e GOOGLE_CLIENT_SECRET no .env (preferido) ou
   salve client_secret.json em backend/ — esse arquivo está no .gitignore e
   NUNCA deve ser commitado.
6. Se o app mobile usar client IDs próprios (Android/iOS), liste-os em
   GOOGLE_ALLOWED_CLIENT_IDS, separados por vírgula.
"""

import json
import os
import logging
import secrets
from flask import Blueprint, request, jsonify, redirect, session
from flask_jwt_extended import create_access_token
from requests_oauthlib import OAuth2Session
from google.oauth2 import id_token
import requests
from sqlalchemy import func

import services.dentista_service as dentista_service
from models.dentista_model import Dentista

logger = logging.getLogger(__name__)

google_auth_bp = Blueprint('google_auth', __name__, url_prefix='/auth/google')

# ---- Configuração OAuth2 ----
# Insecure transport para desenvolvimento local
os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

# URLs do Google
GOOGLE_AUTHORIZATION_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"

# Credenciais OAuth
CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')
CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET')
REDIRECT_URI = os.environ.get('GOOGLE_REDIRECT_URI', 'http://localhost:5000/auth/google/callback')

# Escopos solicitados ao Google
SCOPES = [
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/userinfo.email',
]

# Tenta carregar de client_secret.json como alternativa
if not CLIENT_ID or not CLIENT_SECRET:
    try:
        client_secret_path = os.path.join(os.path.dirname(__file__), '..', 'client_secret.json')
        if os.path.exists(client_secret_path):
            with open(client_secret_path) as f:
                client_data = json.load(f)
                web_config = client_data.get('web', {})
                CLIENT_ID = CLIENT_ID or web_config.get('client_id')
                CLIENT_SECRET = CLIENT_SECRET or web_config.get('client_secret')
                logger.info('Credenciais Google carregadas de client_secret.json')
        else:
            logger.warning('client_secret.json não encontrado. Configure GOOGLE_CLIENT_ID e GOOGLE_CLIENT_SECRET.')
    except Exception as e:
        logger.error(f'Erro ao carregar client_secret.json: {e}')


def _client_ids_aceitos():
    """Client IDs cujos tokens este backend aceita (web + mobile)."""
    extras = os.environ.get('GOOGLE_ALLOWED_CLIENT_IDS', '')
    ids = {i.strip() for i in extras.split(',') if i.strip()}
    if CLIENT_ID:
        ids.add(CLIENT_ID)
    return ids


def _validar_access_token(access_token_str):
    """
    Confere se o access token foi emitido PARA ESTE APP e devolve os dados
    do usuário, ou None.

    Antes o backend só chamava o /userinfo: qualquer access token do Google,
    emitido para qualquer outro app, era aceito — quem tivesse o token de um
    usuário em outro serviço conseguia entrar no ReOdonto como ele.
    """
    resposta = requests.get(
        'https://oauth2.googleapis.com/tokeninfo',
        params={'access_token': access_token_str},
        timeout=10,
    )
    if resposta.status_code != 200:
        logger.warning('tokeninfo recusou o access token: %s', resposta.text)
        return None

    info = resposta.json()
    audiencia = info.get('aud') or info.get('azp')
    if audiencia not in _client_ids_aceitos():
        logger.warning('Access token emitido para outro client_id: %s', audiencia)
        return None

    # O nome não vem no tokeninfo; busca no userinfo com o token já validado.
    perfil = requests.get(
        GOOGLE_USERINFO_URL,
        headers={'Authorization': f'Bearer {access_token_str}'},
        timeout=10,
    )
    if perfil.status_code == 200:
        info.update(perfil.json())
    return info


def _email_verificado(info):
    valor = info.get('email_verified', info.get('verified_email'))
    return valor is True or str(valor).lower() == 'true'


def _entrar_como_dentista(email, nome):
    """
    Encontra o dentista pelo email (ou cria um) e devolve a resposta de login.

    A conta criada recebe uma senha aleatória — quem entra pelo Google não usa
    senha, mas pode definir uma depois pela recuperação de senha. Isso não abre
    nada novo: o cadastro de dentista em POST /dentistas/ já é público.
    """
    dentista = Dentista.query.filter(
        func.lower(Dentista.email) == email.strip().lower()
    ).first()
    if dentista:
        logger.info('Dentista existente entrou com Google: %s', email)
    else:
        dentista = dentista_service.criar_dentista({
            'nome': nome,
            'email': email,
            'senha': secrets.token_urlsafe(16),
        })
        logger.info('Dentista criado via Google: %s', email)

    token = create_access_token(
        identity=str(dentista.id),
        additional_claims={
            'nome': dentista.nome,
            'email': dentista.email,
            'tipo': 'dentista',
            'dentista_id': dentista.id,
            'google_auth': True,
        },
    )
    return jsonify({
        'token': token,
        'dentista': dentista.to_dict(),
        'google_auth': True,
    }), 200


@google_auth_bp.route('/login', methods=['GET'])
def login():
    """
    Inicia o fluxo de autenticação Google.
    Redireciona o usuário para a tela de login do Google.
    """
    if not CLIENT_ID or not CLIENT_SECRET:
        return jsonify({
            'erro': 'Autenticação Google não configurada. Configure GOOGLE_CLIENT_ID e GOOGLE_CLIENT_SECRET ou adicione client_secret.json.'
        }), 500

    # Cria uma sessão OAuth2
    google = OAuth2Session(
        CLIENT_ID,
        redirect_uri=REDIRECT_URI,
        scope=SCOPES,
    )

    # Gera URL de autorização
    authorization_url, state = google.authorization_url(
        GOOGLE_AUTHORIZATION_URL,
        access_type='offline',
        prompt='select_account',
    )

    # Salva o state na sessão para validar no callback
    session['oauth_state'] = state

    return redirect(authorization_url)


@google_auth_bp.route('/callback', methods=['GET'])
def callback():
    """
    Callback do Google após o usuário autorizar.
    Troca o código por um token e obtém os dados do usuário.
    """
    if not CLIENT_ID or not CLIENT_SECRET:
        return jsonify({'erro': 'Autenticação Google não configurada'}), 500

    # Valida o state para evitar CSRF
    oauth_state = session.get('oauth_state')
    if not oauth_state or oauth_state != request.args.get('state'):
        return jsonify({'erro': 'State inválido. Possível ataque CSRF.'}), 401

    # Verifica se houve erro do Google
    error = request.args.get('error')
    if error:
        return jsonify({'erro': f'Erro do Google: {error}'}), 400

    # Obtém o código de autorização
    code = request.args.get('code')
    if not code:
        return jsonify({'erro': 'Código de autorização não recebido'}), 400

    try:
        # Cria uma nova sessão OAuth2 para trocar o código por token
        google = OAuth2Session(
            CLIENT_ID,
            redirect_uri=REDIRECT_URI,
            state=oauth_state,
        )

        # Troca o código por token
        token = google.fetch_token(
            GOOGLE_TOKEN_URL,
            client_secret=CLIENT_SECRET,
            authorization_response=request.url,
        )

        # Obtém os dados do usuário
        user_info = google.get(GOOGLE_USERINFO_URL).json()

        email = user_info.get('email')
        nome = user_info.get('name', 'Usuário Google')
        if not email or not _email_verificado(user_info):
            return jsonify({'erro': 'O Google não confirmou o email desta conta'}), 401

        logger.info('Usuario Google autenticado: %s', email)

        # O state já foi usado; o token do Google não é guardado no cookie de
        # sessão (o cookie do Flask é assinado, mas legível pelo cliente).
        session.pop('oauth_state', None)

        # Em uma app real, você redirecionaria para o frontend com o token na URL
        # Por exemplo: return redirect(f"myapp://login?token={jwt_token}")
        return _entrar_como_dentista(email, nome)

    except Exception as e:
        logger.error(f'Erro no callback Google: {str(e)}', exc_info=True)
        return jsonify({'erro': f'Erro ao processar autenticação: {str(e)}'}), 500


@google_auth_bp.route('/verify-token', methods=['POST'])
def verify_token():
    """
    Verifica e valida o token enviado pelo Flutter/Frontend (web ou mobile).
    
    Web: apenas idToken
    Mobile: pode ter idToken ou accessToken
    """
    if not CLIENT_ID or not CLIENT_SECRET:
        return jsonify({'erro': 'Google OAuth não configurado'}), 500
    
    data = request.get_json(silent=True)
    if not data:
        return jsonify({'erro': 'Body deve ser JSON válido'}), 400
    
    access_token_str = data.get('access_token')
    id_token_str = data.get('id_token')
    
    if not access_token_str and not id_token_str:
        return jsonify({'erro': 'Token não fornecido'}), 400
    
    try:
        token_info = None
        
        # Tenta usar idToken se disponível (web)
        if id_token_str:
            try:
                from google.auth.transport.requests import Request as GoogleRequest
                # A verificação confere assinatura, expiração e audiência.
                token_info = id_token.verify_oauth2_token(
                    id_token_str,
                    GoogleRequest(),
                    list(_client_ids_aceitos()),
                )
                logger.info('ID token verificado com sucesso')
            except Exception as e:
                logger.warning(f'ID token inválido, tentando com accessToken: {e}')
                token_info = None
        
        # Se ID token falhou ou não existe, usa accessToken (mobile) — mas só
        # depois de conferir que ele foi emitido para este app.
        if not token_info and access_token_str:
            token_info = _validar_access_token(access_token_str)
            if not token_info:
                return jsonify({'erro': 'Token inválido'}), 401
            logger.info('Access token validado com sucesso')

        if not token_info:
            return jsonify({'erro': 'Nenhum token válido fornecido'}), 401

        email = token_info.get('email')
        nome = token_info.get('name', 'Usuário Google')

        if not email:
            return jsonify({'erro': 'Email não fornecido pelo Google'}), 400
        if not _email_verificado(token_info):
            return jsonify({'erro': 'O Google não confirmou o email desta conta'}), 401

        logger.info('Token Google verificado para: %s', email)
        return _entrar_como_dentista(email, nome)
        
    except Exception as e:
        logger.error(f'Erro ao verificar token: {str(e)}', exc_info=True)
        return jsonify({'erro': 'Erro ao processar autenticação'}), 500


@google_auth_bp.route('/logout', methods=['POST'])
def logout():
    """
    Faz logout: limpa a sessão.
    """
    session.clear()
    return jsonify({'mensagem': 'Logout realizado com sucesso'}), 200
