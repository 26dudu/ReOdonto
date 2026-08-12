from database.db import db
from models.clinica_model import Clinica


def criar_clinica(data):
    # Validação do campo obrigatório
    if not data.get('nome'):
        raise ValueError('Campo obrigatório ausente: nome')

    clinica = Clinica(
        nome=data['nome'],
        telefone=data.get('telefone'),
        email=data.get('email'),
        cep=data.get('cep'),
        rua=data.get('rua'),
        bairro=data.get('bairro'),
        numero=data.get('numero'),
        cidade=data.get('cidade'),
        estado=data.get('estado'),
    )
    db.session.add(clinica)
    db.session.commit()
    return clinica


def listar_clinicas():
    return Clinica.query.all()


def listar_clinicas_paginado(page=1, per_page=20):
    return Clinica.query.paginate(page=page, per_page=per_page, error_out=False)


def buscar_clinica(id):
    return db.get_or_404(Clinica, id)


def atualizar_clinica(id, data):
    clinica = db.get_or_404(Clinica, id)

    if data.get('nome'):
        clinica.nome = data['nome']
    if data.get('telefone') is not None:
        clinica.telefone = data['telefone']
    if data.get('email') is not None:
        clinica.email = data['email']
    if data.get('cep') is not None:
        clinica.cep = data['cep']
    if data.get('rua') is not None:
        clinica.rua = data['rua']
    if data.get('bairro') is not None:
        clinica.bairro = data['bairro']
    if data.get('numero') is not None:
        clinica.numero = data['numero']
    if data.get('cidade') is not None:
        clinica.cidade = data['cidade']
    if data.get('estado') is not None:
        clinica.estado = data['estado']

    db.session.commit()
    return clinica


def deletar_clinica(id):
    clinica = db.get_or_404(Clinica, id)
    db.session.delete(clinica)
    db.session.commit()
