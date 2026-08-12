from database.db import db


class Consulta(db.Model):
    __tablename__ = 'consulta'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(100), nullable=False)
    descricao = db.Column(db.Text, nullable=False)
    valor = db.Column(db.Float, nullable=False)
    duracao_minutos = db.Column(db.Integer, nullable=True)  # duração estimada da consulta

    def to_dict(self):
        return {
            'id': self.id,
            'nome': self.nome,
            'descricao': self.descricao,
            'valor': self.valor,
            'duracao_minutos': self.duracao_minutos,
        }
