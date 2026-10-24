"""
Serviço de envio e verificação de email para recuperação de senha.

Responsabilidades:
  1. verificar_caixa_de_entrada() — usa imaplib para confirmar que
     a caixa de entrada está acessível no servidor (conexão rápida).
  2. enviar_codigo(destinatario, codigo) — envia o OTP via SMTP/STARTTLS.

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

def enviar_codigo(destinatario: str, codigo: str) -> None:
    """
    Envia email com código OTP de recuperação de senha.

    Fluxo de segurança:
      1. Modo TESTING → apenas loga, nunca envia nem conecta à rede.
      2. Verifica configuração → levanta ConfiguracaoEmailAusente se incompleta.
      3. Verifica caixa via IMAP → levanta MailboxNaoAcessivel se inacessível.
      4. Envia via SMTP com STARTTLS → levanta RuntimeError se falhar.

    O código OTP nunca é incluído nos logs em produção.
    """
    # ── Modo teste ─────────────────────────────────────────────────────────
    testing = (
        os.environ.get('FLASK_TESTING', '').lower() == 'true'
        or os.environ.get('TESTING', '').lower() == 'true'
    )
    if testing:
        # Em testes, loga o código (ambiente controlado, sem dados reais)
        logger.info('[MODO TESTE] Código de recuperação para %s: %s', destinatario, codigo)
        return

    # ── Configuração SMTP ──────────────────────────────────────────────────
    cfg = _config_smtp()

    # ── Verificação IMAP antes de enviar ───────────────────────────────────
    # Levanta MailboxNaoAcessivel se o servidor IMAP estiver indisponível.
    # paciente_service captura essa exceção e decide se bloqueia ou continua.
    verificar_caixa_de_entrada()

    # ── Monta a mensagem ───────────────────────────────────────────────────
    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'ReOdonto — Código de recuperação de senha'
    msg['From']    = cfg['from']
    msg['To']      = destinatario

    texto_simples = (
        f'Seu código de recuperação de senha é: {codigo}\n'
        'Ele expira em 15 minutos.\n\n'
        'Se você não solicitou essa recuperação, ignore este email.'
    )
    html = f"""
    <html><body style="font-family:Arial,sans-serif;color:#1C2434">
    <h2 style="color:#1E5FD8">Recuperação de Senha — ReOdonto</h2>
    <p>Seu código de verificação é:</p>
    <h1 style="letter-spacing:10px;color:#1E5FD8;font-size:36px">{codigo}</h1>
    <p>Este código expira em <strong>15 minutos</strong> e é de uso único.</p>
    <hr style="border:none;border-top:1px solid #E2E8F0"/>
    <p style="font-size:12px;color:#8C9AAB">
      Se você não solicitou a recuperação de senha, ignore este email com segurança.
      Nenhuma alteração foi feita na sua conta.
    </p>
    </body></html>
    """
    msg.attach(MIMEText(texto_simples, 'plain', 'utf-8'))
    msg.attach(MIMEText(html,          'html',  'utf-8'))

    # ── Envio SMTP/STARTTLS ────────────────────────────────────────────────
    try:
        with smtplib.SMTP(cfg['server'], cfg['port'], timeout=10) as smtp:
            smtp.ehlo()
            smtp.starttls()          # Upgrade para TLS antes do LOGIN
            smtp.ehlo()              # Re-identifica após TLS
            smtp.login(cfg['username'], cfg['password'])
            smtp.sendmail(cfg['from'], destinatario, msg.as_string())
        # Não loga o código em produção — só confirma o envio
        logger.info('Email de recuperação enviado para %s', destinatario)
    except smtplib.SMTPException as exc:
        logger.error('Falha SMTP ao enviar para %s: %s', destinatario, exc)
        raise RuntimeError('Falha ao enviar email de recuperação') from exc
    except (socket.timeout, OSError) as exc:
        logger.error('Timeout/rede ao enviar para %s: %s', destinatario, exc)
        raise RuntimeError('Falha de conexão ao enviar email de recuperação') from exc
