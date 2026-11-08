from database.db import db
from models.oferta_model import OfertaAdiantamento


def adicionar(oferta):
    db.session.add(oferta)


def confirmar():
    db.session.commit()


def buscar_por_id(id):
    return db.session.get(OfertaAdiantamento, id)


def listar_pendentes_do_dentista(dentista_id):
    return (
        OfertaAdiantamento.query
        .filter_by(dentista_id=dentista_id, status='pendente')
        .order_by(OfertaAdiantamento.criado_em.desc())
        .all()
    )


def listar_do_vago(vago_id):
    return OfertaAdiantamento.query.filter_by(vago_id=vago_id).all()


def listar_do_agendamento_pendentes(agendamento_id):
    return OfertaAdiantamento.query.filter_by(
        agendamento_id=agendamento_id, status='pendente'
    ).all()
