"""
Recuperação de senha por código (OTP) — vale para dentista e para paciente.

O fluxo nasceu só para paciente, mas quem usa o app é o dentista: antes um
dentista não conseguia recuperar a própria senha. Aqui a busca cobre os dois
tipos de conta. O dentista guarda o email em texto puro na coluna `email`; o
paciente guarda criptografado, com um `email_hash` para busca. O registro do
OTP é indexado pelo hash do email, igual para os dois.

Proteções aplicadas:
  1. Rate-limit de MAX_TENTATIVAS_POR_HORA pedidos por email por hora.
  2. Todos os OTPs ativos anteriores são invalidados antes de gerar um novo.
  3. O código de 6 dígitos vem de secrets (CSPRNG), e só o hash é guardado.
  4. O hash do novo código não pode colidir com nenhum OTP ativo.
  5. O código expira em VALIDADE_MINUTOS.
  6. A comparação do código usa hmac.compare_digest (tempo constante).
  7. O OTP é marcado como usado antes de a nova senha ser salva.
"""
import hmac
import logging
import secrets
from datetime import datetime, timedelta, timezone

import bcrypt
from sqlalchemy import func

from database.db import db
from models.dentista_model import Dentista
from models.paciente_model import Paciente
from models.recuperacao_senha_model import RecuperacaoSenha
from services import email_service
from services.email_service import MailboxNaoAcessivel
from utils.crypto import decrypt_data, hash_data

logger = logging.getLogger(__name__)

MAX_TENTATIVAS_POR_HORA = 3
VALIDADE_MINUTOS = 15
MIN_CARACTERES_SENHA = 8
MAX_TENTATIVAS_COLISAO = 10

# Resultados possíveis de solicitar_codigo
ENVIADO = 'enviado'
NAO_ENCONTRADO = 'nao_encontrado'
LIMITE_EXCEDIDO = 'limite_excedido'


def _buscar_conta(email: str):
    """
    Localiza a conta pelo email e devolve (conta, email_para_envio).

    Procura primeiro entre os dentistas — é quem usa o app. Devolve
    (None, None) quando o email não existe em nenhuma das duas tabelas.
    """
    email_limpo = (email or '').strip()
    if not email_limpo:
        return None, None

    dentista = Dentista.query.filter(
        func.lower(Dentista.email) == email_limpo.lower()
    ).first()
    if dentista:
        return dentista, dentista.email

    paciente = Paciente.query.filter_by(email_hash=hash_data(email_limpo)).first()
    if paciente:
        return paciente, decrypt_data(paciente.email)

    return None, None


def _gerar_codigo_unico():
    """Devolve (codigo, codigo_hash) sem colidir com nenhum OTP ativo."""
    for _ in range(MAX_TENTATIVAS_COLISAO):
        candidato = str(secrets.randbelow(1_000_000)).zfill(6)
        candidato_hash = hash_data(candidato)
        colisao = RecuperacaoSenha.query.filter_by(
            codigo_hash=candidato_hash, usado=False
        ).first()
        if not colisao:
            return candidato, candidato_hash
    return None, None


def solicitar_codigo(email: str) -> str:
    """
    Gera e envia o código de recuperação.

    Devolve ENVIADO, NAO_ENCONTRADO ou LIMITE_EXCEDIDO — o controller traduz
    cada caso em uma resposta HTTP diferente. Antes o limite de tentativas
    devolvia None, e o usuário recebia "Email não encontrado" em vez de uma
    mensagem sobre o limite.
    """
    conta, email_destino = _buscar_conta(email)
    if not conta:
        return NAO_ENCONTRADO

    email_hash = hash_data(email)
    uma_hora_atras = datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(hours=1)

    tentativas = RecuperacaoSenha.query.filter(
        RecuperacaoSenha.email_hash == email_hash,
        RecuperacaoSenha.criado_em >= uma_hora_atras,
    ).count()
    if tentativas >= MAX_TENTATIVAS_POR_HORA:
        logger.warning(
            'Rate-limit atingido para email_hash=%s (%d pedidos na ultima hora)',
            email_hash[:8], tentativas,
        )
        return LIMITE_EXCEDIDO

    # Invalida os OTPs ativos anteriores — só o mais novo vale.
    RecuperacaoSenha.query.filter_by(email_hash=email_hash, usado=False).update(
        {'usado': True}
    )
    db.session.flush()

    codigo, codigo_hash = _gerar_codigo_unico()
    if not codigo:
        db.session.rollback()
        logger.error(
            'Nao foi possivel gerar OTP unico apos %d tentativas', MAX_TENTATIVAS_COLISAO
        )
        raise RuntimeError('Não foi possível gerar o código agora. Tente novamente.')

    registro = RecuperacaoSenha(
        email_hash=email_hash,
        codigo_hash=codigo_hash,
        expira_em=datetime.now(timezone.utc) + timedelta(minutes=VALIDADE_MINUTOS),
        usado=False,
    )
    db.session.add(registro)
    db.session.commit()

    try:
        email_service.enviar_codigo(email_destino, codigo)
    except (MailboxNaoAcessivel, RuntimeError) as exc:
        logger.error(
            'Falha ao enviar OTP para email_hash=%s: %s - codigo salvo, email nao enviado.',
            email_hash[:8], exc,
        )

    return ENVIADO


def redefinir(email: str, codigo: str, nova_senha: str) -> None:
    """Troca a senha da conta usando o código recebido por email."""
    if not nova_senha or len(nova_senha) < MIN_CARACTERES_SENHA:
        raise ValueError(
            f'A nova senha deve ter pelo menos {MIN_CARACTERES_SENHA} caracteres'
        )

    email_hash = hash_data(email)
    codigo_hash = hash_data(codigo)

    registro_valido = None
    for registro in RecuperacaoSenha.query.filter_by(
        email_hash=email_hash, usado=False
    ).all():
        if hmac.compare_digest(registro.codigo_hash, codigo_hash) and registro.esta_valido():
            registro_valido = registro
            break

    if not registro_valido:
        raise ValueError('Código inválido ou expirado')

    conta, _ = _buscar_conta(email)
    if not conta:
        raise ValueError('Conta não encontrada')

    # Marca o OTP como usado antes de salvar a nova senha.
    registro_valido.usado = True
    conta.senha = bcrypt.hashpw(
        nova_senha.encode('utf-8'), bcrypt.gensalt()
    ).decode('utf-8')
    db.session.commit()
