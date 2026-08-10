import os
from flask import Flask
from database.db import db
from controllers.paciente_controller import paciente_bp
from controllers.dentista_controller import dentista_bp
from controllers.clinica_controller import clinica_bp
from controllers.consulta_controller import consulta_bp
from controllers.agendamento_controller import agendamento_bp

app = Flask(__name__)
db_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'database')
os.makedirs(db_dir, exist_ok=True)
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{os.path.join(db_dir, "odonto.db")}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

app.register_blueprint(paciente_bp)
app.register_blueprint(dentista_bp)
app.register_blueprint(clinica_bp)
app.register_blueprint(consulta_bp)
app.register_blueprint(agendamento_bp)

with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(debug=True)
