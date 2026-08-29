import re
import bcrypt
from database.db import db
from models.dentista_model import Dentista


def _hash_senha(senha: str) -> str:
    return bcrypt.hashpw(senha.encode(), bcrypt.gensalt()).decode()


def _verificar_senha(senha: str, hash_armazenado: str) -> bool:
    return bcrypt.checkpw(senha.encode(), hash_armazenado.encode())


def _somente_digitos(valor: str) -> str:
    return re.sub(r'\D', '', valor)


def _validar_cpf(cpf: str) -> bool:
    """Valida CPF com dígitos verificadores."""
    if len(cpf) != 11 or cpf == cpf[0] * 11:
        return False
    for pos in range(9, 11):
        soma = sum(int(cpf[i]) * (pos + 1 - i) for i in range(pos))
        digito = (soma * 10 % 11) % 10
        if digito != int(cpf[pos]):
            return False
    return True


def _validar_cnpj(cnpj: str) -> bool:
    """Valida CNPJ com dígitos verificadores."""
    if len(cnpj) != 14 or cnpj == cnpj[0] * 14:
        return False
    pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    pesos2 = [6] + pesos1
    for pesos, pos in ((pesos1, 12), (pesos2, 13)):
        soma = sum(int(cnpj[i]) * pesos[i] for i in range(pos))
        resto = soma % 11
        digito = 0 if resto < 2 else 11 - resto
        if digito != int(cnpj[pos]):
            return False
    return True


def criar_dentista(data):
    campos_obrigatorios = ['nome', 'email', 'senha']
    for campo in campos_obrigatorios:
        if not data.get(campo):
            raise ValueError(f'Campo obrigatório ausente: {campo}')

    # Valida senha mínima
    if len(data['senha']) < 6:
        raise ValueError('A senha deve ter pelo menos 6 caracteres')

    if Dentista.query.filter_by(email=data['email']).first():
        raise ValueError('Email já cadastrado')

    # Processa CPF ou CNPJ
    cpf_cnpj_raw = data.get('cpf_cnpj')
    cpf_cnpj = None
    if cpf_cnpj_raw:
        cpf_cnpj = _somente_digitos(cpf_cnpj_raw)
        if len(cpf_cnpj) == 11:
            if not _validar_cpf(cpf_cnpj):
                raise ValueError('CPF inválido')
        elif len(cpf_cnpj) == 14:
            if not _validar_cnpj(cpf_cnpj):
                raise ValueError('CNPJ inválido')
        else:
            raise ValueError('CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos')

        if Dentista.query.filter_by(cpf_cnpj=cpf_cnpj).first():
            raise ValueError('CPF/CNPJ já cadastrado')

    dentista = Dentista(
        nome=data['nome'],
        email=data['email'],
        senha=_hash_senha(data['senha']),
        telefone=data.get('telefone'),
        cro=data.get('cro'),
        cpf_cnpj=cpf_cnpj,
    )
    db.session.add(dentista)
    db.session.commit()
    return dentista


def login_dentista(email: str, senha: str) -> Dentista:
    dentista = Dentista.query.filter_by(email=email).first()
    if not dentista or not _verificar_senha(senha, dentista.senha):
        raise ValueError('Email ou senha inválidos')
    return dentista


def listar_dentistas(clinica_id: int | None = None):
    if clinica_id:
        from models.agendamento_model import Agendamento
        ids = (
            db.session.query(Agendamento.dentista_id)
            .filter(Agendamento.clinica_id == clinica_id)
            .distinct()
            .all()
        )
        id_list = [row[0] for row in ids]
        if not id_list:
            return []
        return Dentista.query.filter(Dentista.id.in_(id_list)).all()
    return Dentista.query.all()


def buscar_dentista(id):
    return db.get_or_404(Dentista, id)


def atualizar_dentista(id, data):
    dentista = db.get_or_404(Dentista, id)

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
    if data.get('cpf_cnpj') is not None:
        novo = _somente_digitos(data['cpf_cnpj'])
        if novo and novo != dentista.cpf_cnpj:
            if len(novo) == 11:
                if not _validar_cpf(novo):
                    raise ValueError('CPF inválido')
            elif len(novo) == 14:
                if not _validar_cnpj(novo):
                    raise ValueError('CNPJ inválido')
            else:
                raise ValueError('CPF deve ter 11 ou CNPJ deve ter 14 dígitos')
            if Dentista.query.filter_by(cpf_cnpj=novo).first():
                raise ValueError('CPF/CNPJ já está em uso')
            dentista.cpf_cnpj = novo
    if data.get('senha'):
        dentista.senha = _hash_senha(data['senha'])

    db.session.commit()
    return dentista


def deletar_dentista(id):
    dentista = db.get_or_404(Dentista, id)
    db.session.delete(dentista)
    db.session.commit()
