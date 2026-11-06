from database.db import db
from models.recuperacao_senha_model import RecuperacaoSenha


def existe_codigo_ativo(codigo_hash):
    return RecuperacaoSenha.query.filter_by(
        codigo_hash=codigo_hash, usado=False
    ).first() is not None


def contar_pedidos_desde(email_hash, desde):
    return RecuperacaoSenha.query.filter(
        RecuperacaoSenha.email_hash == email_hash,
        RecuperacaoSenha.criado_em >= desde,
    ).count()


def invalidar_codigos_ativos(email_hash):
    RecuperacaoSenha.query.filter_by(email_hash=email_hash, usado=False).update(
        {'usado': True}
    )
    db.session.flush()


def listar_codigos_ativos(email_hash):
    return RecuperacaoSenha.query.filter_by(
        email_hash=email_hash, usado=False
    ).all()


def adicionar(registro):
    db.session.add(registro)


def desfazer():
    db.session.rollback()


def confirmar():
    db.session.commit()
