import os
import logging
import secrets
from datetime import timedelta
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from database.db import db
from controllers.paciente_controller import paciente_bp
from controllers.dentista_controller import dentista_bp
from controllers.clinica_controller import clinica_bp
from controllers.agendamento_controller import agendamento_bp
from controllers.consulta_controller import consulta_bp
from controllers.painel_controller import painel_bp
from controllers.cep_controller import cep_bp
from controllers.google_auth_controller import google_auth_bp

# Carrega variáveis do arquivo .env se existir (python-dotenv opcional)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # python-dotenv não instalado — usa variáveis de ambiente do sistema

# --- Logging ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
)
logger = logging.getLogger(__name__)

app = Flask(__name__)


def _chave_secreta(nome: str) -> str:
    """
    Lê uma chave secreta da variável de ambiente `nome`.

    Nenhuma chave fica escrita no código. Sem a variável definida, gera uma
    chave aleatória válida só para esta execução: o app sobe normalmente em
    desenvolvimento, mas os tokens já emitidos deixam de valer a cada
    reinício. Defina as chaves no .env (veja .env.example).
    """
    valor = os.environ.get(nome)
    if valor:
        return valor
    logger.warning(
        '%s nao definida - gerando chave aleatoria so para esta execucao. '
        'Os tokens deixam de valer a cada reinicio. Defina %s no .env '
        '(veja .env.example).', nome, nome,
    )
    return secrets.token_hex(32)


# --- Segurança ---
app.config['SECRET_KEY'] = _chave_secreta('SECRET_KEY')
app.config['SESSION_COOKIE_SECURE'] = False   # True em produção (HTTPS)
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['JWT_SECRET_KEY'] = _chave_secreta('JWT_SECRET_KEY')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=8)  # token expira em 8h

# CORS — em produção substitua '*' pelo domínio real do app
CORS(app, origins=os.environ.get('CORS_ORIGINS', '*'), supports_credentials=False)

jwt = JWTManager(app)

# --- Proteção de Content-Type em rotas que recebem JSON ---
# Rejeita requisições POST/PUT/PATCH sem o header correto (evita CSRF simples)
@app.before_request
def verificar_content_type():
    if request.method in ('POST', 'PUT', 'PATCH'):
        # Rotas públicas de leitura (GET do CEP) não chegam aqui,
        # mas rotas de escrita devem enviar JSON
        ct = request.content_type or ''
        if request.data and 'application/json' not in ct:
            return jsonify({'erro': 'Content-Type deve ser application/json'}), 415

# --- Handlers JWT — sempre retornam JSON limpo ---

@jwt.unauthorized_loader
def token_ausente(motivo):
    return jsonify({'erro': 'Token ausente. Faça login para continuar.'}), 401

@jwt.invalid_token_loader
def token_invalido(motivo):
    return jsonify({'erro': 'Token inválido. Faça login novamente.'}), 401

@jwt.expired_token_loader
def token_expirado(jwt_header, jwt_data):
    return jsonify({'erro': 'Sessão expirada. Faça login novamente.'}), 401

@jwt.revoked_token_loader
def token_revogado(jwt_header, jwt_data):
    return jsonify({'erro': 'Token revogado. Faça login novamente.'}), 401

# --- Banco SQLite ---
db_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'database')
os.makedirs(db_dir, exist_ok=True)
# DATABASE_URL permite apontar para outro banco (testes, outro ambiente)
# sem editar o código; sem ela, usa o SQLite local de sempre.
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'DATABASE_URL', f'sqlite:///{os.path.join(db_dir, "odonto.db")}'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

# --- Habilitar Foreign Keys no SQLite ---
from sqlalchemy import event
from sqlalchemy.engine import Engine
import sqlite3

@event.listens_for(Engine, 'connect')
def habilitar_foreign_keys(dbapi_connection, connection_record):
    if isinstance(dbapi_connection, sqlite3.Connection):
        cursor = dbapi_connection.cursor()
        cursor.execute('PRAGMA foreign_keys=ON')
        cursor.close()

# --- Blueprints ---
app.register_blueprint(paciente_bp)
app.register_blueprint(dentista_bp)
app.register_blueprint(clinica_bp)
app.register_blueprint(agendamento_bp)
app.register_blueprint(consulta_bp)
app.register_blueprint(painel_bp)
app.register_blueprint(cep_bp)
app.register_blueprint(google_auth_bp)

# --- Registra modelos adicionais para que db.create_all() crie as tabelas ---
import models.recuperacao_senha_model  # noqa: F401 — registra tabela recuperacao_senha

def _aplicar_colunas_novas():
    """
    Adiciona ao banco já existente as colunas que o código passou a usar.

    db.create_all() só cria tabelas que faltam, não altera as que existem, e
    o projeto não usa Alembic. Sem isto, um odonto.db criado antes destas
    colunas quebraria em toda consulta de agendamento.
    """
    from sqlalchemy import inspect, text

    colunas_por_tabela = {
        'agendamento': {
            'duracao_minutos': 'INTEGER',
            'valor': 'FLOAT',
            'encaixe': 'BOOLEAN NOT NULL DEFAULT 0',
        },
    }

    inspetor = inspect(db.engine)
    for tabela, colunas in colunas_por_tabela.items():
        if not inspetor.has_table(tabela):
            continue
        existentes = {coluna['name'] for coluna in inspetor.get_columns(tabela)}
        for nome, tipo in colunas.items():
            if nome in existentes:
                continue
            db.session.execute(text(f'ALTER TABLE {tabela} ADD COLUMN {nome} {tipo}'))
            logger.info('Coluna %s.%s adicionada ao banco existente.', tabela, nome)
    db.session.commit()


# --- Criar tabelas ---
with app.app_context():
    db.create_all()
    _aplicar_colunas_novas()
    logger.info('Banco de dados inicializado.')

# --- Handlers globais de erro (sempre retornam JSON) ---

@app.errorhandler(400)
def bad_request(e):
    return jsonify({'erro': 'Requisição inválida', 'detalhe': str(e)}), 400

@app.errorhandler(401)
def unauthorized(e):
    return jsonify({'erro': 'Não autorizado. Faça login para continuar.'}), 401

@app.errorhandler(403)
def forbidden(e):
    return jsonify({'erro': 'Acesso negado'}), 403

@app.errorhandler(404)
def not_found(e):
    return jsonify({'erro': 'Recurso não encontrado'}), 404

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({'erro': 'Método HTTP não permitido nesta rota'}), 405

@app.errorhandler(500)
def internal_error(e):
    logger.error('Erro interno: %s', str(e), exc_info=True)
    return jsonify({'erro': 'Erro interno do servidor'}), 500


if __name__ == '__main__':
    debug = os.environ.get('FLASK_DEBUG', 'false').lower() == 'true'
    app.run(debug=debug)
