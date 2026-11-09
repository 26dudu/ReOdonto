from database.db import db
from models.verificacao_email_model import VerificacaoEmail


def contar_pedidos_desde(email_hash, desde):
    return VerificacaoEmail.query.filter(
        VerificacaoEmail.email_hash == email_hash,
        VerificacaoEmail.criado_em >= desde,
    ).count()


def invalidar_codigos_ativos(email_hash):
    VerificacaoEmail.query.filter_by(email_hash=email_hash, usado=False).update(
        {'usado': True}
    )
    db.session.flush()


def buscar_codigo_ativo(email_hash):
    return (
        VerificacaoEmail.query.filter_by(email_hash=email_hash, usado=False)
        .order_by(VerificacaoEmail.criado_em.desc())
        .first()
    )


def buscar_ultimo_pedido(email_hash):
    return (
        VerificacaoEmail.query.filter_by(email_hash=email_hash)
        .order_by(VerificacaoEmail.criado_em.desc(), VerificacaoEmail.id.desc())
        .first()
    )


def remover_do_email(email_hash):
    VerificacaoEmail.query.filter_by(email_hash=email_hash).delete()
    db.session.flush()


def adicionar(registro):
    db.session.add(registro)


def confirmar():
    db.session.commit()
