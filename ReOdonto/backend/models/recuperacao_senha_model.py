from database.db import db
from models.otp_mixin import OtpMixin, agora_utc


class RecuperacaoSenha(OtpMixin, db.Model):
    __tablename__ = 'recuperacao_senha'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    email_hash = db.Column(db.String(64), nullable=False, index=True)  # SHA-256 do email
    codigo_hash = db.Column(db.String(64), nullable=False)              # SHA-256 do código OTP
    expira_em = db.Column(db.DateTime, nullable=False)                  # Expiração em 15 minutos
    usado = db.Column(db.Boolean, default=False, nullable=False)        # Token já utilizado?
    criado_em = db.Column(db.DateTime, default=agora_utc, nullable=False)
