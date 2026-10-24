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


import logging as _logging
_logger = _logging.getLogger(__name__)


def solicitar_recuperacao_senha(email: str) -> bool:
    """
    Inicia o fluxo de recuperação de senha.

    Proteções de segurança aplicadas:
      1. Email só é processado se existir no banco (email_hash lookup).
         Se não existir, retorna False silenciosamente — sem revelar que o
         email não está cadastrado (evita enumeração de usuários).
      2. Rate-limit: máximo de MAX_TENTATIVAS_POR_HORA por email por hora.
      3. Todos os OTPs anteriores ativos do email são invalidados antes de
         gerar um novo (evita que múltiplos OTPs válidos coexistam).
      4. O código OTP (6 dígitos) é gerado com secrets.randbelow — CSPRNG.
      5. Garantia de unicidade: o hash do novo código não pode colidir com
         nenhum hash de OTP ativo no banco.
      6. OTP expira em 15 minutos.
      7. Verificação de caixa via IMAP antes do envio — se o servidor de
         email estiver indisponível, o registro OTP já foi salvo e o erro
         é logado, mas o fluxo retorna sem revelar detalhes ao cliente.
    """
    from datetime import datetime, timedelta, timezone
    from models.recuperacao_senha_model import RecuperacaoSenha
    from services import email_service
    from services.email_service import MailboxNaoAcessivel
    import secrets

    # ── 1. Verifica existência no banco ────────────────────────────────────
    email_hash = hash_data(email)
    paciente = Paciente.query.filter_by(email_hash=email_hash).first()
    if not paciente:
        return False

    # ── 2. Rate-limit: máx. MAX_TENTATIVAS_POR_HORA tentativas por hora ───
    MAX_TENTATIVAS_POR_HORA = 3
    uma_hora_atras = datetime.now(timezone.utc) - timedelta(hours=1)

    tentativas_recentes = RecuperacaoSenha.query.filter(
        RecuperacaoSenha.email_hash == email_hash,
        RecuperacaoSenha.criado_em >= uma_hora_atras.replace(tzinfo=None),
    ).count()

    if tentativas_recentes >= MAX_TENTATIVAS_POR_HORA:
        _logger.warning(
            'Rate-limit atingido para email_hash=%s (%d tentativas na última hora)',
            email_hash[:8],
            tentativas_recentes,
        )
        return

    # ── 3. Invalida todos os OTPs ativos anteriores ────────────────────────
    RecuperacaoSenha.query.filter_by(
        email_hash=email_hash, usado=False
    ).update({'usado': True})
    db.session.flush()

    # ── 4 + 5. Gera OTP único com CSPRNG e garante unicidade do hash ───────
    MAX_TENTATIVAS_COLISAO = 10
    codigo = None
    codigo_hash = None
    for _ in range(MAX_TENTATIVAS_COLISAO):
        candidato = str(secrets.randbelow(1_000_000)).zfill(6)
        candidato_hash = hash_data(candidato)
        colisao = RecuperacaoSenha.query.filter_by(
            codigo_hash=candidato_hash, usado=False
        ).first()
        if not colisao:
            codigo = candidato
            codigo_hash = candidato_hash
            break

    if not codigo:
        _logger.error('Não foi possível gerar OTP único após %d tentativas', MAX_TENTATIVAS_COLISAO)
        return

    # ── 6. Persiste o registro OTP ─────────────────────────────────────────
    registro = RecuperacaoSenha(
        email_hash=email_hash,
        codigo_hash=codigo_hash,
        expira_em=datetime.now(timezone.utc) + timedelta(minutes=15),
        usado=False,
    )
    db.session.add(registro)
    db.session.commit()

    # ── 7. Envia o email ───────────────────────────────────────────────────
    email_decriptado = decrypt_data(paciente.email)
    try:
        email_service.enviar_codigo(email_decriptado, codigo)
    except MailboxNaoAcessivel as exc:
        _logger.error(
            'IMAP indisponível para %s: %s — OTP salvo mas email não enviado.',
            email_hash[:8], exc
        )
    except RuntimeError as exc:
        _logger.error(
            'Falha SMTP para %s: %s — OTP salvo mas email não enviado.',
            email_hash[:8], exc
        )

    return True


def redefinir_senha(email: str, codigo: str, nova_senha: str) -> None:
    """
    Redefine a senha usando o OTP recebido por email.

    Proteções de segurança:
      1. Valida força mínima da nova senha (mín. 8 chars).
      2. Busca o registro OTP por email_hash + codigo_hash — nunca por id.
      3. Usa hmac.compare_digest para comparar hashes em tempo constante,
         evitando ataques de timing.
      4. Verifica validade (não expirado + não usado) antes de aceitar.
      5. Marca o OTP como usado ANTES de commitar a nova senha.
    """
    import hmac
    from models.recuperacao_senha_model import RecuperacaoSenha

    # ── Valida força da nova senha ─────────────────────────────────────────
    if not nova_senha or len(nova_senha) < 8:
        raise ValueError('A nova senha deve ter pelo menos 8 caracteres')

    # ── Lookup por email_hash + codigo_hash ────────────────────────────────
    email_hash = hash_data(email)
    codigo_hash = hash_data(codigo)

    registros_ativos = RecuperacaoSenha.query.filter_by(
        email_hash=email_hash,
        usado=False,
    ).all()

    registro_valido = None
    for r in registros_ativos:
        if hmac.compare_digest(r.codigo_hash, codigo_hash) and r.esta_valido():
            registro_valido = r
            break

    if not registro_valido:
        raise ValueError('Código inválido ou expirado')

    # ── Busca o paciente ───────────────────────────────────────────────────
    paciente = Paciente.query.filter_by(email_hash=email_hash).first()
    if not paciente:
        raise ValueError('Paciente não encontrado')

    # ── Atualiza: marca OTP como usado ANTES de salvar a nova senha ────────
    registro_valido.usado = True
    senha_hash = bcrypt.hashpw(nova_senha.encode('utf-8'), bcrypt.gensalt())
    paciente.senha = senha_hash.decode('utf-8')
    db.session.commit()
