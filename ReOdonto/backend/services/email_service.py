"""
Serviço de envio de email com código OTP (recuperação de senha e verificação de email).

Responsabilidades:
  1. verificar_caixa_de_entrada() — usa imaplib para confirmar que
     a caixa de entrada está acessível no servidor (conexão rápida).
  2. enviar_codigo(destinatario, codigo) — OTP de recuperação de senha.
  3. enviar_codigo_verificacao(destinatario, codigo) — OTP de verificação de email.

Os dois envios compartilham o mesmo caminho (_enviar_otp): só o assunto e o
texto mudam.

Variáveis de ambiente necessárias:
  MAIL_SERVER   - ex: smtp.gmail.com
  MAIL_PORT     - porta SMTP (ex: 587 — padrão STARTTLS)
  MAIL_IMAP_PORT- porta IMAP (ex: 993 — padrão SSL; opcional, default 993)
  MAIL_USERNAME - ex: seu_email@gmail.com
  MAIL_PASSWORD - ex: sua_app_password  (Gmail: senha de app, não a senha normal)
  MAIL_FROM     - ex: noreply@reodonto.com  (opcional, padrão = MAIL_USERNAME)

Segurança implementada:
  - IMAP sobre SSL (imaplib.IMAP4_SSL) — credenciais nunca trafegam em claro
  - SMTP com STARTTLS explícito — upgrade obrigatório antes do LOGIN
  - Timeout em todas as conexões de rede (5-10s) — evita hang indefinido
  - O código OTP nunca é logado em produção — só em modo TESTING
"""

import imaplib
import email
from email.header import decode_header
import os
import smtplib
import socket
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Exceções próprias — permitem tratamento granular no serviço que chama
# ---------------------------------------------------------------------------

class MailboxNaoAcessivel(Exception):
    """Levantada quando o IMAP não consegue conectar."""


class ConfiguracaoEmailAusente(Exception):
    """Levantada quando as variáveis de ambiente de email não estão configuradas."""


# ---------------------------------------------------------------------------
# Helpers de configuração
# ---------------------------------------------------------------------------

def _config_smtp() -> dict:
    """Retorna as configurações SMTP ou levanta ConfiguracaoEmailAusente."""
    server   = os.environ.get('MAIL_SERVER')
    username = os.environ.get('MAIL_USERNAME')
    password = os.environ.get('MAIL_PASSWORD')
    if not all([server, username, password]):
        raise ConfiguracaoEmailAusente(
            'MAIL_SERVER, MAIL_USERNAME e MAIL_PASSWORD são obrigatórios.'
        )
    return {
        'server':   server,
        'port':     int(os.environ.get('MAIL_PORT', 587)),
        'username': username,
        'password': password,
        'from':     os.environ.get('MAIL_FROM') or username,
    }


def _config_imap() -> dict:
    """Retorna as configurações IMAP."""
    smtp = _config_smtp()
    return {
        'server':   os.environ.get('MAIL_IMAP_SERVER') or smtp['server'],
        'port':     int(os.environ.get('MAIL_IMAP_PORT', 993)),
        'username': smtp['username'],
        'password': smtp['password'],
    }


# ---------------------------------------------------------------------------
# 1. Verificação de caixa via IMAP
# ---------------------------------------------------------------------------

def verificar_caixa_de_entrada() -> None:
    """
    Verifica via IMAP se a caixa de entrada está acessível (conexão rápida).

    Estratégia:
      - Abre IMAP4_SSL com timeout de 5s
      - Faz login rápido
      - Seleciona INBOX — confirma autenticação
      - Fecha imediatamente

    Se o IMAP falhar, levanta MailboxNaoAcessivel (paciente_service continua).

    Raises:
      MailboxNaoAcessivel — se não foi possível conectar.
      ConfiguracaoEmailAusente — se variáveis não estão configuradas.
    """
    cfg = _config_imap()

    try:
        # Conexão SSL com timeout curto (5s)
        imap = imaplib.IMAP4_SSL(cfg['server'], cfg['port'], timeout=5)

        # Login rápido
        imap.login(cfg['username'], cfg['password'])

        # Seleciona INBOX (verifica que o login funcionou)
        status, _ = imap.select('INBOX', readonly=True)
        if status != 'OK':
            imap.logout()
            raise MailboxNaoAcessivel('Não foi possível selecionar a INBOX.')

        imap.logout()
        logger.debug('IMAP: caixa de entrada acessível')

    except (imaplib.IMAP4.error, socket.timeout, OSError) as exc:
        logger.warning('IMAP: falha ao verificar caixa: %s', exc)
        raise MailboxNaoAcessivel(f'Falha ao verificar caixa de entrada: {exc}') from exc


# ---------------------------------------------------------------------------
# 2. Envio do OTP via SMTP
# ---------------------------------------------------------------------------

VALIDADE_TEXTO = '15 minutos'


def _modo_teste() -> bool:
    return (
        os.environ.get('FLASK_TESTING', '').lower() == 'true'
        or os.environ.get('TESTING', '').lower() == 'true'
    )


def _montar_mensagem(cfg: dict, destinatario: str, assunto: str,
                     titulo: str, introducao: str, codigo: str,
                     aviso: str) -> MIMEMultipart:
    msg = MIMEMultipart('alternative')
    msg['Subject'] = assunto
    msg['From']    = cfg['from']
    msg['To']      = destinatario

    texto_simples = (
        f'{introducao} {codigo}\n'
        f'Ele expira em {VALIDADE_TEXTO}.\n\n'
        f'{aviso}'
    )
    html = f"""
    <html><body style="font-family:Arial,sans-serif;color:#1C2434">
    <h2 style="color:#1E5FD8">{titulo}</h2>
    <p>Seu código de verificação é:</p>
    <h1 style="letter-spacing:10px;color:#1E5FD8;font-size:36px">{codigo}</h1>
    <p>Este código expira em <strong>{VALIDADE_TEXTO}</strong> e é de uso único.</p>
    <hr style="border:none;border-top:1px solid #E2E8F0"/>
    <p style="font-size:12px;color:#8C9AAB">{aviso}</p>
    </body></html>
    """
    msg.attach(MIMEText(texto_simples, 'plain', 'utf-8'))
    msg.attach(MIMEText(html,          'html',  'utf-8'))
    return msg


def _enviar_otp(destinatario: str, codigo: str, *, finalidade: str, assunto: str,
                titulo: str, introducao: str, aviso: str) -> None:
    """
    Fluxo de segurança comum a todo envio de OTP:
      1. Modo TESTING → apenas loga, nunca envia nem conecta à rede.
      2. Verifica configuração → levanta ConfiguracaoEmailAusente se incompleta.
      3. Verifica caixa via IMAP → levanta MailboxNaoAcessivel se inacessível.
      4. Envia via SMTP com STARTTLS → levanta RuntimeError se falhar.

    O código OTP nunca é incluído nos logs em produção.
    """
    if _modo_teste():
        logger.info('[MODO TESTE] Código de %s para %s: %s', finalidade, destinatario, codigo)
        return

    cfg = _config_smtp()
    verificar_caixa_de_entrada()
    msg = _montar_mensagem(cfg, destinatario, assunto, titulo, introducao, codigo, aviso)

    try:
        with smtplib.SMTP(cfg['server'], cfg['port'], timeout=10) as smtp:
            smtp.ehlo()
            smtp.starttls()          # Upgrade para TLS antes do LOGIN
            smtp.ehlo()              # Re-identifica após TLS
            smtp.login(cfg['username'], cfg['password'])
            smtp.sendmail(cfg['from'], destinatario, msg.as_string())
        logger.info('Email de %s enviado para %s', finalidade, destinatario)
    except smtplib.SMTPException as exc:
        logger.error('Falha SMTP ao enviar para %s: %s', destinatario, exc)
        raise RuntimeError(f'Falha ao enviar email de {finalidade}') from exc
    except (socket.timeout, OSError) as exc:
        logger.error('Timeout/rede ao enviar para %s: %s', destinatario, exc)
        raise RuntimeError(f'Falha de conexão ao enviar email de {finalidade}') from exc


def enviar_codigo(destinatario: str, codigo: str) -> None:
    """Envia o código de recuperação de senha."""
    _enviar_otp(
        destinatario, codigo,
        finalidade='recuperação de senha',
        assunto='ReOdonto — Código de recuperação de senha',
        titulo='Recuperação de Senha — ReOdonto',
        introducao='Seu código de recuperação de senha é:',
        aviso=(
            'Se você não solicitou a recuperação de senha, ignore este email com '
            'segurança. Nenhuma alteração foi feita na sua conta.'
        ),
    )


def enviar_codigo_verificacao(destinatario: str, codigo: str) -> None:
    """Envia o código de verificação de email do cadastro."""
    _enviar_otp(
        destinatario, codigo,
        finalidade='verificação de email',
        assunto='ReOdonto — Confirme seu email',
        titulo='Confirme seu email — ReOdonto',
        introducao='Seu código para confirmar o email é:',
        aviso=(
            'Se você não criou uma conta no ReOdonto, ignore este email com '
            'segurança. Nenhuma conta será ativada sem este código.'
        ),
    )
