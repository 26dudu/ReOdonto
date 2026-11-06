from database.db import db
from models.consulta_model import Consulta


def buscar_ou_404(id):
    return db.get_or_404(Consulta, id)


def listar_todos():
    return Consulta.query.all()


def adicionar(consulta):
    db.session.add(consulta)


def remover(consulta):
    db.session.delete(consulta)


def confirmar():
    db.session.commit()
