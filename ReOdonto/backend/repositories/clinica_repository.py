from database.db import db
from models.clinica_model import Clinica


def buscar_ou_404(id):
    return db.get_or_404(Clinica, id)


def listar_todos():
    return Clinica.query.all()


def adicionar(clinica):
    db.session.add(clinica)


def remover(clinica):
    db.session.delete(clinica)


def confirmar():
    db.session.commit()


def listar_paginado(page=1, per_page=20):
    return Clinica.query.paginate(page=page, per_page=per_page, error_out=False)


def buscar_por_id(id):
    return db.session.get(Clinica, id)
