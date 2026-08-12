from database.db import db
from models.paciente_model import Paciente
import bcrypt


def criar_paciente(data):
    # Validação dos campos obrigatórios
    campos_obrigatorios = ['nome', 'email', 'senha']
    for campo in campos_obrigatorios:
        if not data.get(campo):
            raise ValueError(f'Campo obrigatório ausente: {campo}')

    # Verifica email duplicado antes de tentar inserir
    if Paciente.query.filter_by(email=data['email']).first():
        raise ValueError('Email já cadastrado')

    # Verifica CPF duplicado se fornecido
    if data.get('cpf') and Paciente.query.filter_by(cpf=data['cpf']).first():
        raise ValueError('CPF já cadastrado')

    # Hash da senha — nunca salvar em texto puro
    senha_hash = bcrypt.hashpw(data['senha'].encode('utf-8'), bcrypt.gensalt())

    paciente = Paciente(
        nome=data['nome'],
        email=data['email'],
        senha=senha_hash.decode('utf-8'),
        telefone=data.get('telefone'),
        cpf=data.get('cpf'),
        cep=data.get('cep'),
        rua=data.get('rua'),
        bairro=data.get('bairro'),
        numero=data.get('numero'),
    )
    db.session.add(paciente)
    db.session.commit()
    return paciente


def listar_pacientes():
    return Paciente.query.all()


def buscar_paciente(id):
    return db.get_or_404(Paciente, id)


def atualizar_paciente(id, data):
    paciente = db.get_or_404(Paciente, id)

    # Se tentar mudar o email, verificar se já está em uso por outro paciente
    novo_email = data.get('email')
    if novo_email and novo_email != paciente.email:
        if Paciente.query.filter_by(email=novo_email).first():
            raise ValueError('Email já está em uso')
        paciente.email = novo_email

    # Se tentar mudar o CPF, verificar duplicata
    novo_cpf = data.get('cpf')
    if novo_cpf and novo_cpf != paciente.cpf:
        if Paciente.query.filter_by(cpf=novo_cpf).first():
            raise ValueError('CPF já está em uso')
        paciente.cpf = novo_cpf

    # Atualiza os demais campos se vierem no payload
    if data.get('nome'):
        paciente.nome = data['nome']
    if data.get('telefone') is not None:
        paciente.telefone = data['telefone']
    if data.get('cep') is not None:
        paciente.cep = data['cep']
    if data.get('rua') is not None:
        paciente.rua = data['rua']
    if data.get('bairro') is not None:
        paciente.bairro = data['bairro']
    if data.get('numero') is not None:
        paciente.numero = data['numero']

    # Troca de senha — requer hash
    if data.get('senha'):
        senha_hash = bcrypt.hashpw(data['senha'].encode('utf-8'), bcrypt.gensalt())
        paciente.senha = senha_hash.decode('utf-8')

    db.session.commit()
    return paciente


def deletar_paciente(id):
    paciente = db.get_or_404(Paciente, id)
    db.session.delete(paciente)
    db.session.commit()


def buscar_paciente_por_email(email):
    """Busca paciente pelo email — usado no login."""
    paciente = Paciente.query.filter_by(email=email).first()
    if not paciente:
        raise ValueError('Email ou senha inválidos')
    return paciente


def verificar_senha(paciente, senha_texto):
    """Utilitário para checar senha no login."""
    return bcrypt.checkpw(senha_texto.encode('utf-8'), paciente.senha.encode('utf-8'))
