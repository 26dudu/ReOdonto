import os
import logging
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from database.db import db
from controllers.paciente_controller import paciente_bp
from controllers.dentista_controller import dentista_bp
from controllers.clinica_controller import clinica_bp
from controllers.consulta_controller import consulta_bp
from controllers.agendamento_controller import agendamento_bp
from controllers.cep_controller import cep_bp

# --- Logging ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# --- Segurança ---
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-troque-em-producao')
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', 'jwt-secret-troque-em-producao')

# CORS restrito — em produção troque pelo domínio real do app
allowed_origins = os.environ.get('ALLOWED_ORIGINS', 'http://localhost:*').split(',')
CORS(app, origins=allowed_origins)

JWTManager(app)

# --- Banco SQLite ---
db_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'database')
os.makedirs(db_dir, exist_ok=True)
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{os.path.join(db_dir, "odonto.db")}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

# --- Habilitar Foreign Keys no SQLite ---
# SQLite não habilita FK por padrão — sem isso, agendamentos com IDs inválidos são aceitos
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
app.register_blueprint(consulta_bp)
app.register_blueprint(agendamento_bp)
app.register_blueprint(cep_bp)

# --- Criar tabelas ---
with app.app_context():
    db.create_all()
    logger.info('Banco de dados inicializado.')

# --- Handlers globais de erro (sempre retornam JSON) ---

@app.errorhandler(400)
def bad_request(e):
    return jsonify({'erro': 'Requisição inválida', 'detalhe': str(e)}), 400

@app.errorhandler(401)
def unauthorized(e):
    return jsonify({'erro': 'Não autorizado'}), 401

@app.errorhandler(404)
def not_found(e):
    return jsonify({'erro': 'Recurso não encontrado'}), 404

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({'erro': 'Método HTTP não permitido nesta rota'}), 405

@app.errorhandler(422)
def unprocessable(e):
    return jsonify({'erro': 'Token inválido ou expirado'}), 422

@app.errorhandler(500)
def internal_error(e):
    logger.error('Erro interno: %s', str(e), exc_info=True)
    return jsonify({'erro': 'Erro interno do servidor'}), 500


if __name__ == '__main__':
    debug = os.environ.get('FLASK_DEBUG', 'false').lower() == 'true'
    app.run(debug=debug)
