from database.db import db
from models.otp_mixin import OtpMixin, agora_utc


class VerificacaoEmail(OtpMixin, db.Model):
    __tablename__ = 'verificacao_email'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    email_hash = db.Column(db.String(64), nullable=False, index=True)
    codigo_hash = db.Column(db.String(64), nullable=False)
    dados_cadastro = db.Column(db.Text, nullable=False)
    expira_em = db.Column(db.DateTime, nullable=False)
    tentativas = db.Column(db.Integer, default=0, nullable=False)
    usado = db.Column(db.Boolean, default=False, nullable=False)
    criado_em = db.Column(db.DateTime, default=agora_utc, nullable=False)
