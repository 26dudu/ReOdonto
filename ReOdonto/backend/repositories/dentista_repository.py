from sqlalchemy import func

from database.db import db
from models.agendamento_model import Agendamento
from models.dentista_model import Dentista


def buscar_ou_404(id):
    return db.get_or_404(Dentista, id)


def buscar_por_email(email):
    return Dentista.query.filter(
        func.lower(Dentista.email) == (email or '').strip().lower()
    ).first()


def email_em_uso_por_outro(email, dentista_id):
    return Dentista.query.filter(
        func.lower(Dentista.email) == email.strip().lower(),
        Dentista.id != dentista_id,
    ).first()


def buscar_por_cpf_cnpj(cpf_cnpj):
    return Dentista.query.filter_by(cpf_cnpj=cpf_cnpj).first()


def listar_todos():
    return Dentista.query.all()


def listar_por_clinica(clinica_id):
    ids = (
        db.session.query(Agendamento.dentista_id)
        .filter(Agendamento.clinica_id == clinica_id)
        .distinct()
    )
    return Dentista.query.filter(Dentista.id.in_(ids)).all()


def adicionar(dentista):
    db.session.add(dentista)


def remover(dentista):
    db.session.delete(dentista)


def confirmar():
    db.session.commit()


def buscar_por_id(id):
    return db.session.get(Dentista, id)
