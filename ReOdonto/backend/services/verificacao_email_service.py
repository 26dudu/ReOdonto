"""
Verificação de email no cadastro do dentista, por código (OTP).

A conta só passa a existir depois que o código é digitado. Enquanto isso, os
dados do cadastro (com a senha já em hash bcrypt) ficam guardados junto do
código em `verificacao_email`. Este serviço cuida só do código e dos dados
pendentes; quem cria o Dentista é o dentista_service.

Proteções aplicadas:
  1. No máximo MAX_PEDIDOS_POR_HORA códigos por email por hora.
  2. Um novo pedido invalida os códigos anteriores — só o mais novo vale.
  3. O código de 6 dígitos vem de secrets (CSPRNG) e só o hash é guardado.
  4. Depois de MAX_TENTATIVAS_ERRADAS erros o código é invalidado, o que
     impede adivinhar os 6 dígitos por força bruta.
  5. A comparação usa hmac.compare_digest (tempo constante).
  6. O código expira em VALIDADE_MINUTOS.
"""
import hmac
import json
import logging
import secrets
from datetime import datetime, timedelta, timezone

from models.verificacao_email_model import VerificacaoEmail
from repositories import verificacao_email_repository as repo
from services import email_service
from services.email_service import MailboxNaoAcessivel
from utils.crypto import hash_data

logger = logging.getLogger(__name__)

MAX_PEDIDOS_POR_HORA = 3
MAX_TENTATIVAS_ERRADAS = 5
VALIDADE_MINUTOS = 15

ENVIADO = 'enviado'
NAO_ENCONTRADO = 'nao_encontrado'
LIMITE_EXCEDIDO = 'limite_excedido'

MENSAGEM_CODIGO_INVALIDO = 'Código inválido ou expirado'


def _gerar_codigo() -> str:
    return str(secrets.randbelow(1_000_000)).zfill(6)


def _agora_utc_ingenuo() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def registrar_pedido(dados: dict) -> str:
    """Guarda os dados do cadastro pendente e envia o código para o email."""
    email_hash = hash_data(dados['email'])

    desde = _agora_utc_ingenuo() - timedelta(hours=1)
    if repo.contar_pedidos_desde(email_hash, desde) >= MAX_PEDIDOS_POR_HORA:
        logger.warning('Limite de verificação atingido para email_hash=%s', email_hash[:8])
        return LIMITE_EXCEDIDO

    repo.invalidar_codigos_ativos(email_hash)

    codigo = _gerar_codigo()
    repo.adicionar(VerificacaoEmail(
        email_hash=email_hash,
        codigo_hash=hash_data(codigo),
        dados_cadastro=json.dumps(dados),
        expira_em=datetime.now(timezone.utc) + timedelta(minutes=VALIDADE_MINUTOS),
    ))
    repo.confirmar()

    try:
        email_service.enviar_codigo_verificacao(dados['email'], codigo)
    except (MailboxNaoAcessivel, RuntimeError) as exc:
        logger.error(
            'Falha ao enviar verificação para email_hash=%s: %s - código salvo, email não enviado.',
            email_hash[:8], exc,
        )

    return ENVIADO


def reenviar(email: str) -> str:
    """Envia um código novo para um cadastro que ainda está pendente."""
    registro = repo.buscar_ultimo_pedido(hash_data(email))
    if not registro:
        return NAO_ENCONTRADO
    return registrar_pedido(json.loads(registro.dados_cadastro))


def validar_codigo(email: str, codigo: str) -> dict:
    """
    Confere o código e devolve os dados do cadastro pendente.

    O código é consumido: só vale uma vez. Levanta ValueError quando o código
    está errado, expirado, já usado ou não existe cadastro pendente.
    """
    registro = repo.buscar_codigo_ativo(hash_data(email))
    if not registro or not registro.esta_valido():
        raise ValueError(MENSAGEM_CODIGO_INVALIDO)

    if not hmac.compare_digest(registro.codigo_hash, hash_data(codigo)):
        registro.tentativas += 1
        if registro.tentativas >= MAX_TENTATIVAS_ERRADAS:
            registro.usado = True
        repo.confirmar()
        raise ValueError(MENSAGEM_CODIGO_INVALIDO)

    registro.usado = True
    repo.confirmar()
    return json.loads(registro.dados_cadastro)


def descartar(email: str) -> None:
    """Apaga os pedidos do email depois que a conta foi criada."""
    repo.remover_do_email(hash_data(email))
    repo.confirmar()
