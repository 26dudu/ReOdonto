from models.clinica_model import Clinica
from repositories import clinica_repository as repo


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
    repo.adicionar(clinica)
    repo.confirmar()
    return clinica


def listar_clinicas():
    return repo.listar_todos()


def listar_clinicas_paginado(page=1, per_page=20):
    return repo.listar_paginado(page, per_page)


def buscar_clinica(id):
    return repo.buscar_ou_404(id)


def atualizar_clinica(id, data):
    clinica = repo.buscar_ou_404(id)

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

    repo.confirmar()
    return clinica


def deletar_clinica(id):
    clinica = repo.buscar_ou_404(id)
    repo.remover(clinica)
    repo.confirmar()
