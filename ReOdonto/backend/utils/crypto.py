import os
import base64
import hashlib
import logging
from cryptography.fernet import Fernet

logger = logging.getLogger(__name__)


def _carregar_chave() -> str:
    """
    Devolve uma chave Fernet válida a partir da variável ENCRYPTION_KEY.

    A chave nunca fica escrita no código. Sem a variável definida, uma chave
    efêmera é gerada agora e vale só enquanto o processo viver — nesse caso os
    dados criptografados em execuções anteriores deixam de ser legíveis, por
    isso o aviso. Defina ENCRYPTION_KEY no .env antes de guardar dado real.
    """
    key_str = os.environ.get('ENCRYPTION_KEY')

    if not key_str:
        logger.warning(
            'ENCRYPTION_KEY nao definida - usando chave efemera gerada agora. '
            'Dados criptografados em execucoes anteriores nao serao legiveis. '
            'Defina ENCRYPTION_KEY no .env (veja .env.example).'
        )
        return Fernet.generate_key().decode('utf-8')

    # Aceita uma chave Fernet pronta (32 bytes em base64 url-safe) ou uma
    # senha livre, que é derivada para 32 bytes com SHA-256.
    try:
        if len(base64.urlsafe_b64decode(key_str.encode('utf-8'))) == 32:
            return key_str
    except Exception:
        pass

    return base64.urlsafe_b64encode(
        hashlib.sha256(key_str.encode('utf-8')).digest()
    ).decode('utf-8')


fernet = Fernet(_carregar_chave().encode('utf-8'))


def encrypt_data(value: str) -> str:
    """Criptografa uma string com Fernet (simétrico)."""
    if not value:
        return value
    return fernet.encrypt(value.encode('utf-8')).decode('utf-8')


def decrypt_data(value: str) -> str:
    """
    Descriptografa uma string Fernet.

    Devolve o valor original quando a descriptografia falha — acontece com
    registros gravados em texto puro antes da criptografia existir, ou quando
    a ENCRYPTION_KEY mudou desde que o dado foi gravado.
    """
    if not value:
        return value
    try:
        return fernet.decrypt(value.encode('utf-8')).decode('utf-8')
    except Exception:
        logger.debug('Falha ao descriptografar um valor — devolvendo como está.')
        return value


def hash_data(value: str) -> str:
    """
    Gera o SHA-256 de um CPF ou email para busca indexada no banco.

    Normaliza antes (minúsculas, sem espaços e sem pontuação de CPF/CNPJ)
    para que o mesmo dado sempre produza o mesmo hash.
    """
    if not value:
        return value
    normalized = value.strip().lower()
    normalized = normalized.replace('.', '').replace('-', '').replace('/', '')
    return hashlib.sha256(normalized.encode('utf-8')).hexdigest()
