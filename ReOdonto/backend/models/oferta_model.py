from datetime import datetime

from database.db import db


class OfertaAdiantamento(db.Model):
    __tablename__ = 'oferta_adiantamento'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    dentista_id = db.Column(db.Integer, db.ForeignKey('dentista.id'), nullable=False)
    vago_id = db.Column(db.Integer, nullable=False)
    agendamento_id = db.Column(db.Integer, nullable=False)
    telefone = db.Column(db.String(30), nullable=False, index=True)
    rodada = db.Column(db.Integer, nullable=False, default=1)
    status = db.Column(db.String(20), nullable=False, default='pendente')
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.now)
    expira_em = db.Column(db.DateTime, nullable=False)

    def expirada(self, agora=None) -> bool:
        return (agora or datetime.now()) >= self.expira_em
