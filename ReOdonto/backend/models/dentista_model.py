from database.db import db


class Dentista(db.Model):
    __tablename__ = 'dentista'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(150), nullable=False, unique=True)
    telefone = db.Column(db.String(20), nullable=True)
    cro = db.Column(db.String(20), nullable=True)       # registro profissional

    def to_dict(self):
        return {
            'id': self.id,
            'nome': self.nome,
            'email': self.email,
            'telefone': self.telefone,
            'cro': self.cro,
        }
