from database.db import db
from datetime import datetime, timezone


def _agora_utc() -> datetime:
    """Retorna o instante atual em UTC com timezone info (substitui datetime.utcnow())."""
    return datetime.now(timezone.utc)


class RecuperacaoSenha(db.Model):
    __tablename__ = 'recuperacao_senha'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    email_hash = db.Column(db.String(64), nullable=False, index=True)  # SHA-256 do email
    codigo_hash = db.Column(db.String(64), nullable=False)              # SHA-256 do código OTP
    expira_em = db.Column(db.DateTime, nullable=False)                  # Expiração em 15 minutos
    usado = db.Column(db.Boolean, default=False, nullable=False)        # Token já utilizado?
    criado_em = db.Column(db.DateTime, default=_agora_utc, nullable=False)

    def esta_expirado(self) -> bool:
        # expira_em pode não ter tzinfo (banco SQLite não persiste timezone)
        expira = self.expira_em
        if expira.tzinfo is None:
            expira = expira.replace(tzinfo=timezone.utc)
        return _agora_utc() > expira

    def esta_valido(self) -> bool:
        return not self.usado and not self.esta_expirado()
