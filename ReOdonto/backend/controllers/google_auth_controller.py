"""
Autenticação Google OAuth2 para ReOdonto.

Fluxo:
1. Frontend solicita login Google → /auth/google/login
2. Backend redireciona para Google → usuario faz login/autoriza
3. Google redireciona para /auth/google/callback com código
4. Backend troca código por token Google
5. Backend obtém user_info do Google
6. Backend cria ou atualiza paciente no banco
7. Backend retorna JWT + dados do paciente para o frontend

SETUP NO GOOGLE CONSOLE:
1. Vá para https://console.cloud.google.com
2. Crie um novo projeto
3. Ative a API "Google+ API"
4. Crie credenciais OAuth 2.0 (tipo: Web application)
   - URIs autorizados: http://localhost:5000
   - URIs de redirecionamento autorizados: http://localhost:5000/auth/google/callback
5. Baixe client_secret.json e salve em backend/
6. Atualize CLIENT_ID, CLIENT_SECRET e REDIRECT_URI abaixo se necessário
"""

import json
import os
import logging
from flask import Blueprint, request, jsonify, redirect, url_for, session
from flask_jwt_extended import create_access_token
from requests_oauthlib import OAuth2Session
import google.oauth2.service_account
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import services.paciente_service as paciente_service

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

        logger.info(f'Usuário Google autenticado: {user_info.get("email")}')

        # Processa o usuário no banco
        email = user_info.get('email')
        nome = user_info.get('name', 'Usuário Google')
        foto = user_info.get('picture')

        # Tenta buscar paciente por email
        try:
            paciente = paciente_service.buscar_paciente_por_email(email)
            logger.info(f'Paciente existente: {email}')
        except ValueError:
            # Paciente não existe — cria um novo
            # Senha é gerada aleatoriamente (usuário não usa senha com Google)
            import secrets
            senha_temporaria = secrets.token_urlsafe(16)

            paciente_data = {
                'nome': nome,
                'email': email,
                'senha': senha_temporaria,
                'telefone': None,
                'cpf': None,
                'cep': None,
                'rua': None,
                'bairro': None,
                'numero': None,
            }
            paciente = paciente_service.criar_paciente(paciente_data)
            logger.info(f'Novo paciente criado: {email}')

        # Gera JWT para o frontend
        paciente_dict = paciente.to_dict()
        additional_claims = {
            'nome': paciente_dict.get('nome'),
            'email': paciente_dict.get('email'),
            'tipo': 'paciente',
            'google_auth': True,
        }
        jwt_token = create_access_token(
            identity=str(paciente.id),
            additional_claims=additional_claims,
        )

        # Salva dados na sessão para posterior uso
        session['oauth_token'] = token
        session['user_id'] = paciente.id
        session['user_email'] = email
        session['user_name'] = nome
        session['user_picture'] = foto
        session['user_logged_in'] = True

        # Retorna o JWT ao frontend
        # Em uma app real, você redirecionaria para o frontend com o token na URL
        # Por exemplo: return redirect(f"myapp://login?token={jwt_token}")
        return jsonify({
            'token': jwt_token,
            'paciente': paciente_dict,
            'google_auth': True,
        }), 200

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
                token_info = id_token.verify_oauth2_token(
                    id_token_str,
                    GoogleRequest(),
                    CLIENT_ID,
                )
                if token_info.get('aud') != CLIENT_ID:
                    raise ValueError('Token não é para este aplicativo')
                logger.info('ID token verificado com sucesso')
            except Exception as e:
                logger.warning(f'ID token inválido, tentando com accessToken: {e}')
                token_info = None
        
        # Se ID token falhou ou não existe, usa accessToken (mobile)
        if not token_info and access_token_str:
            import requests
            response = requests.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {access_token_str}'},
                timeout=10
            )
            if response.status_code != 200:
                logger.error(f'Erro ao buscar user info: {response.text}')
                return jsonify({'erro': 'Token inválido'}), 401
            token_info = response.json()
            logger.info('User info obtido via accessToken com sucesso')
        
        if not token_info:
            return jsonify({'erro': 'Nenhum token válido fornecido'}), 401
        
        email = token_info.get('email')
        nome = token_info.get('name', 'Usuário Google')
        
        if not email:
            return jsonify({'erro': 'Email não fornecido pelo Google'}), 400
        
        logger.info(f'Token Google verificado para: {email}')
        
        # Processa o usuário no banco
        try:
            paciente = paciente_service.buscar_paciente_por_email(email)
            logger.info(f'Paciente existente: {email}')
        except ValueError:
            # Paciente não existe — cria um novo
            import secrets
            senha_temporaria = secrets.token_urlsafe(16)
            
            paciente_data = {
                'nome': nome,
                'email': email,
                'senha': senha_temporaria,
                'telefone': None,
                'cpf': None,
                'cep': None,
                'rua': None,
                'bairro': None,
                'numero': None,
            }
            paciente = paciente_service.criar_paciente(paciente_data)
            logger.info(f'Novo paciente criado: {email}')
        
        # Gera JWT para o frontend
        paciente_dict = paciente.to_dict()
        additional_claims = {
            'nome': paciente_dict.get('nome'),
            'email': paciente_dict.get('email'),
            'tipo': 'paciente',
            'google_auth': True,
        }
        jwt_token = create_access_token(
            identity=str(paciente.id),
            additional_claims=additional_claims,
        )
        
        return jsonify({
            'token': jwt_token,
            'paciente': paciente_dict,
            'google_auth': True,
        }), 200
        
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
