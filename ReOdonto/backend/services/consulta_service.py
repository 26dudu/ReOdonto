from database.db import db
from models.consulta_model import Consulta


def criar_consulta(data):
    # Validação dos campos obrigatórios
    campos_obrigatorios = ['nome', 'descricao', 'valor']
    for campo in campos_obrigatorios:
        if data.get(campo) is None:
            raise ValueError(f'Campo obrigatório ausente: {campo}')

    # valor deve ser número positivo
    try:
        valor = float(data['valor'])
    except (TypeError, ValueError):
        raise ValueError('Valor inválido para o campo valor')
    if valor < 0:
        raise ValueError('O valor da consulta não pode ser negativo')

    consulta = Consulta(
        nome=data['nome'],
        descricao=data['descricao'],
        valor=valor,
        duracao_minutos=data.get('duracao_minutos'),
    )
    db.session.add(consulta)
    db.session.commit()
    return consulta


def listar_consultas():
    return Consulta.query.all()


def buscar_consulta(id):
    return db.get_or_404(Consulta, id)


def atualizar_consulta(id, data):
    consulta = db.get_or_404(Consulta, id)

    if data.get('nome'):
        consulta.nome = data['nome']
    if data.get('descricao') is not None:
        consulta.descricao = data['descricao']
    if data.get('valor') is not None:
        try:
            valor = float(data['valor'])
        except (TypeError, ValueError):
            raise ValueError('Valor inválido para o campo valor')
        if valor < 0:
            raise ValueError('O valor da consulta não pode ser negativo')
        consulta.valor = valor
    if data.get('duracao_minutos') is not None:
        consulta.duracao_minutos = data['duracao_minutos']

    db.session.commit()
    return consulta


def deletar_consulta(id):
    consulta = db.get_or_404(Consulta, id)
    db.session.delete(consulta)
    db.session.commit()
