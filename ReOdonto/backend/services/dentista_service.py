from database.db import db
from models.dentista_model import Dentista


def criar_dentista(data):
    # Validação dos campos obrigatórios
    campos_obrigatorios = ['nome', 'email']
    for campo in campos_obrigatorios:
        if not data.get(campo):
            raise ValueError(f'Campo obrigatório ausente: {campo}')

    # Verifica email duplicado
    if Dentista.query.filter_by(email=data['email']).first():
        raise ValueError('Email já cadastrado')

    dentista = Dentista(
        nome=data['nome'],
        email=data['email'],
        telefone=data.get('telefone'),
        cro=data.get('cro'),
    )
    db.session.add(dentista)
    db.session.commit()
    return dentista


def listar_dentistas():
    return Dentista.query.all()


def buscar_dentista(id):
    return db.get_or_404(Dentista, id)


def atualizar_dentista(id, data):
    dentista = db.get_or_404(Dentista, id)

    # Verifica duplicata de email se estiver mudando
    novo_email = data.get('email')
    if novo_email and novo_email != dentista.email:
        if Dentista.query.filter_by(email=novo_email).first():
            raise ValueError('Email já está em uso')
        dentista.email = novo_email

    if data.get('nome'):
        dentista.nome = data['nome']
    if data.get('telefone') is not None:
        dentista.telefone = data['telefone']
    if data.get('cro') is not None:
        dentista.cro = data['cro']

    db.session.commit()
    return dentista


def deletar_dentista(id):
    dentista = db.get_or_404(Dentista, id)
    db.session.delete(dentista)
    db.session.commit()
