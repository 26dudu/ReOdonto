from database.db import db
from models.paciente_model import Paciente
import bcrypt
from utils.crypto import encrypt_data, decrypt_data, hash_data
from services.brasilapi_cep import buscar_cep as api_buscar_cep


def _validar_cep_endereco(cep, rua, bairro):
    """Auxiliary to validate that the provided rua/bairro match BrasilAPI's values."""
    if not cep:
        return
    try:
        endereco_real = api_buscar_cep(cep)
        rua_real = endereco_real.get('logradouro', '')
        bairro_real = endereco_real.get('bairro', '')
        # Only validate if the API returns non-empty values
        if rua_real and rua and rua.strip().lower() != rua_real.strip().lower():
            raise ValueError('Endereço inválido: a rua informada diverge do CEP')
        if bairro_real and bairro and bairro.strip().lower() != bairro_real.strip().lower():
            raise ValueError('Endereço inválido: o bairro informado diverge do CEP')
    except Exception as e:
        if isinstance(e, ValueError):
            raise e
        # Network errors can be logged, we don't block registration if BrazilAPI is down
        pass


def criar_paciente(data):
    # Validação dos campos obrigatórios
    campos_obrigatorios = ['nome', 'email', 'senha']
    for campo in campos_obrigatorios:
        if not data.get(campo):
            raise ValueError(f'Campo obrigatório ausente: {campo}')

    # Validate CEP addresses match the BrasilAPI
    _validar_cep_endereco(data.get('cep'), data.get('rua'), data.get('bairro'))

    # Verifica email duplicado usando hash
    email_hash = hash_data(data['email'])
    if Paciente.query.filter_by(email_hash=email_hash).first():
        raise ValueError('Email já cadastrado')

    # Verifica CPF duplicado se fornecido
    cpf_hash = None
    if data.get('cpf'):
        cpf_hash = hash_data(data['cpf'])
        if Paciente.query.filter_by(cpf_hash=cpf_hash).first():
            raise ValueError('CPF já cadastrado')

    # Hash da senha — nunca salvar em texto puro
    senha_hash = bcrypt.hashpw(data['senha'].encode('utf-8'), bcrypt.gensalt())

    paciente = Paciente(
        nome=encrypt_data(data['nome']),
        email=encrypt_data(data['email']),
        email_hash=email_hash,
        senha=senha_hash.decode('utf-8'),
        telefone=encrypt_data(data.get('telefone')),
        cpf=encrypt_data(data.get('cpf')),
        cpf_hash=cpf_hash,
        cep=encrypt_data(data.get('cep')),
        rua=encrypt_data(data.get('rua')),
        bairro=encrypt_data(data.get('bairro')),
        numero=encrypt_data(data.get('numero')),
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

    # Se alterar CEP, rua ou bairro, validar correspondência
    novo_cep = data.get('cep', decrypt_data(paciente.cep))
    nova_rua = data.get('rua', decrypt_data(paciente.rua))
    novo_bairro = data.get('bairro', decrypt_data(paciente.bairro))
    if data.get('cep') or data.get('rua') or data.get('bairro'):
        _validar_cep_endereco(novo_cep, nova_rua, novo_bairro)

    # Se tentar mudar o email, verificar se já está em uso por outro paciente
    novo_email = data.get('email')
    if novo_email and hash_data(novo_email) != paciente.email_hash:
        novo_email_hash = hash_data(novo_email)
        if Paciente.query.filter_by(email_hash=novo_email_hash).first():
            raise ValueError('Email já está em uso')
        paciente.email = encrypt_data(novo_email)
        paciente.email_hash = novo_email_hash

    # Se tentar mudar o CPF, verificar duplicata
    novo_cpf = data.get('cpf')
    if novo_cpf and hash_data(novo_cpf) != paciente.cpf_hash:
        novo_cpf_hash = hash_data(novo_cpf)
        if Paciente.query.filter_by(cpf_hash=novo_cpf_hash).first():
            raise ValueError('CPF já está em uso')
        paciente.cpf = encrypt_data(novo_cpf)
        paciente.cpf_hash = novo_cpf_hash

    # Atualiza os demais campos se vierem no payload
    if data.get('nome'):
        paciente.nome = encrypt_data(data['nome'])
    if data.get('telefone') is not None:
        paciente.telefone = encrypt_data(data['telefone'])
    if data.get('cep') is not None:
        paciente.cep = encrypt_data(data['cep'])
    if data.get('rua') is not None:
        paciente.rua = encrypt_data(data['rua'])
    if data.get('bairro') is not None:
        paciente.bairro = encrypt_data(data['bairro'])
    if data.get('numero') is not None:
        paciente.numero = encrypt_data(data['numero'])

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
    email_hash = hash_data(email)
    paciente = Paciente.query.filter_by(email_hash=email_hash).first()
    if not paciente:
        raise ValueError('Email ou senha inválidos')
    return paciente


def verificar_senha(paciente, senha_texto):
    """Utilitário para checar senha no login."""
    return bcrypt.checkpw(senha_texto.encode('utf-8'), paciente.senha.encode('utf-8'))


# O fluxo de recuperação de senha saiu daqui para services/recuperacao_service.py,
# que atende dentista e paciente. As rotas continuam em /pacientes e agora
# existem também em /dentistas.
