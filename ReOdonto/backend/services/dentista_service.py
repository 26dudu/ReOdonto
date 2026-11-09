import re
import bcrypt
from models.dentista_model import Dentista
from repositories import agendamento_repository, dentista_repository as repo
from services import verificacao_email_service

# Mesmo mínimo que o app já exige em validadores.dart — antes o backend
# aceitava 6, deixando a regra mais fraca que a da tela de cadastro.
MIN_CARACTERES_SENHA = 8


class EmailNaoVerificado(ValueError):
    def __init__(self, email: str):
        super().__init__('Cadastro não concluído. Cadastre-se de novo para confirmar seu email.')
        self.email = email


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


def _validar_cadastro(data) -> dict:
    campos_obrigatorios = ['nome', 'email', 'senha']
    for campo in campos_obrigatorios:
        if not data.get(campo):
            raise ValueError(f'Campo obrigatório ausente: {campo}')

    # Valida senha mínima
    if len(data['senha']) < MIN_CARACTERES_SENHA:
        raise ValueError(
            f'A senha deve ter pelo menos {MIN_CARACTERES_SENHA} caracteres'
        )

    # Comparação sem diferenciar maiúsculas: email não é case-sensitive, e
    # antes "Joao@x.com" e "joao@x.com" podiam coexistir como contas distintas.
    email = data['email'].strip()
    if repo.buscar_por_email(email):
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

        if repo.buscar_por_cpf_cnpj(cpf_cnpj):
            raise ValueError('CPF/CNPJ já cadastrado')

    return {
        'nome': data['nome'],
        'email': email,
        'senha_hash': _hash_senha(data['senha']),
        'telefone': data.get('telefone'),
        'cro': data.get('cro'),
        'cpf_cnpj': cpf_cnpj,
    }


def _gravar_dentista(dados: dict, email_verificado: bool) -> Dentista:
    dentista = Dentista(
        nome=dados['nome'],
        email=dados['email'],
        senha=dados['senha_hash'],
        telefone=dados.get('telefone'),
        cro=dados.get('cro'),
        cpf_cnpj=dados.get('cpf_cnpj'),
        email_verificado=email_verificado,
    )
    repo.adicionar(dentista)
    repo.confirmar()
    return dentista


def _remover_cadastro_nao_verificado(email: str) -> None:
    """
    Apaga uma conta que ficou sem email confirmado (criada antes de o código
    ser exigido antes do cadastro), liberando o email para um novo cadastro.
    """
    existente = repo.buscar_por_email(email)
    if existente and not existente.email_verificado:
        repo.remover(existente)
        repo.confirmar()


def solicitar_cadastro(data) -> str:
    """
    Primeira etapa do cadastro: valida os dados e envia o código por email.

    Nenhuma conta é criada aqui. Ela só nasce em confirmar_cadastro, quando o
    código é digitado. Devolve ENVIADO ou LIMITE_EXCEDIDO.
    """
    _remover_cadastro_nao_verificado((data.get('email') or '').strip())
    dados = _validar_cadastro(data)
    return verificacao_email_service.registrar_pedido(dados)


def confirmar_cadastro(email: str, codigo: str) -> Dentista:
    """Segunda etapa: com o código certo, cria a conta já verificada."""
    dados = verificacao_email_service.validar_codigo(email, codigo)

    if repo.buscar_por_email(dados['email']):
        raise ValueError('Email já cadastrado')
    if dados.get('cpf_cnpj') and repo.buscar_por_cpf_cnpj(dados['cpf_cnpj']):
        raise ValueError('CPF/CNPJ já cadastrado')

    dentista = _gravar_dentista(dados, email_verificado=True)
    verificacao_email_service.descartar(dados['email'])
    return dentista


def criar_dentista(data, email_verificado: bool = True) -> Dentista:
    """Cria a conta direto, sem código. Uso interno (seed e login Google)."""
    return _gravar_dentista(_validar_cadastro(data), email_verificado)


def marcar_email_verificado(dentista: Dentista) -> None:
    if not dentista.email_verificado:
        dentista.email_verificado = True
        repo.confirmar()


def login_dentista(email: str, senha: str) -> Dentista:
    dentista = repo.buscar_por_email(email)
    if not dentista or not _verificar_senha(senha, dentista.senha):
        raise ValueError('Email ou senha inválidos')
    if not dentista.email_verificado:
        raise EmailNaoVerificado(dentista.email)
    return dentista


def listar_dentistas(clinica_id: int | None = None):
    if clinica_id:
        return repo.listar_por_clinica(clinica_id)
    return repo.listar_todos()


def buscar_dentista(id):
    return repo.buscar_ou_404(id)


def atualizar_dentista(id, data):
    dentista = repo.buscar_ou_404(id)

    novo_email = (data.get('email') or '').strip()
    if novo_email and novo_email.lower() != dentista.email.lower():
        if repo.email_em_uso_por_outro(novo_email, dentista.id):
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
            if repo.buscar_por_cpf_cnpj(novo):
                raise ValueError('CPF/CNPJ já está em uso')
            dentista.cpf_cnpj = novo
    # Troca de senha pelo perfil exige a senha atual: só o token não basta,
    # senão um token vazado permitiria tomar a conta trocando a senha.
    if data.get('senha'):
        senha_atual = data.get('senha_atual')
        if not senha_atual:
            raise ValueError('Informe a senha atual para definir uma nova senha')
        if not _verificar_senha(senha_atual, dentista.senha):
            raise ValueError('Senha atual incorreta')
        if len(data['senha']) < MIN_CARACTERES_SENHA:
            raise ValueError(
                f'A nova senha deve ter pelo menos {MIN_CARACTERES_SENHA} caracteres'
            )
        dentista.senha = _hash_senha(data['senha'])

    repo.confirmar()
    return dentista


def deletar_dentista(id):
    """
    Apaga o dentista e os agendamentos dele.

    O PRAGMA foreign_keys=ON do SQLite recusa apagar um dentista que ainda
    tem agendamentos, então a exclusão falhava com erro 500 em vez de
    funcionar. Os agendamentos saem primeiro, na mesma transação.
    """
    dentista = repo.buscar_ou_404(id)
    agendamento_repository.remover_do_dentista(id)
    repo.remover(dentista)
    repo.confirmar()
