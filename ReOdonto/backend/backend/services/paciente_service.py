from database.db import db
from models.paciente_model import Paciente

def criar_paciente(data):
    paciente = Paciente(nome=data['nome'])
    db.session.add(paciente)
    db.session.commit()
    return paciente

def listar_pacientes():
    return Paciente.query.all()

def buscar_paciente(id):
    return Paciente.query.get_or_404(id)

def atualizar_paciente(id, data):
    paciente = Paciente.query.get_or_404(id)
    paciente.nome = data['nome']
    db.session.commit()
    return paciente

def deletar_paciente(id):
    paciente = Paciente.query.get_or_404(id)
    db.session.delete(paciente)
    db.session.commit()
