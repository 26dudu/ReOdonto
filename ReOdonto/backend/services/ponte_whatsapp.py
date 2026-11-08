import logging
import os
import threading

import requests

logger = logging.getLogger(__name__)

ASSINCRONO = True


def _url():
    return os.environ.get('PONTE_WHATSAPP_URL', '').rstrip('/')


def enviar(telefone, mensagem):
    base = _url()
    if not base:
        logger.info('PONTE_WHATSAPP_URL não definida: mensagem para %s não enviada', telefone)
        return False
    try:
        resposta = requests.post(
            f'{base}/enviar',
            json={'telefone': telefone, 'mensagem': mensagem},
            headers={'X-API-Key': os.environ.get('INTEGRACAO_API_KEY', '')},
            timeout=10,
        )
        if resposta.status_code != 200:
            logger.warning('Ponte recusou o envio (%s): %s', resposta.status_code, resposta.text[:200])
            return False
        return True
    except requests.RequestException as erro:
        logger.warning('Falha ao falar com a ponte do WhatsApp: %s', erro)
        return False


def notificar(telefone, mensagem):
    if ASSINCRONO:
        threading.Thread(target=enviar, args=(telefone, mensagem), daemon=True).start()
        return None
    return enviar(telefone, mensagem)
