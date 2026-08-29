from database.db import db


class Dentista(db.Model):
    __tablename__ = 'dentista'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(150), nullable=False, unique=True)
    senha = db.Column(db.String(255), nullable=False)
    telefone = db.Column(db.String(20), nullable=True)
    cro = db.Column(db.String(20), nullable=True)
    # CPF (11 dígitos) ou CNPJ (14 dígitos) — somente números, único
    cpf_cnpj = db.Column(db.String(14), nullable=True, unique=True)

    def to_dict(self):
        return {
            'id': self.id,
            'nome': self.nome,
            'email': self.email,
            'telefone': self.telefone,
            'cro': self.cro,
            'cpf_cnpj': self.cpf_cnpj,
        }
