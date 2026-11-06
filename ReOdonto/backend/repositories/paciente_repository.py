from database.db import db
from models.paciente_model import Paciente


def buscar_ou_404(id):
    return db.get_or_404(Paciente, id)


def buscar_por_email_hash(email_hash):
    return Paciente.query.filter_by(email_hash=email_hash).first()


def buscar_por_cpf_hash(cpf_hash):
    return Paciente.query.filter_by(cpf_hash=cpf_hash).first()


def listar_todos():
    return Paciente.query.all()


def adicionar(paciente):
    db.session.add(paciente)


def remover(paciente):
    db.session.delete(paciente)


def confirmar():
    db.session.commit()
