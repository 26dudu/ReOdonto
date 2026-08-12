from database.db import db


class Clinica(db.Model):
    __tablename__ = 'clinica'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(100), nullable=False)
    telefone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(150), nullable=True)
    cep = db.Column(db.String(9), nullable=True)
    rua = db.Column(db.String(150), nullable=True)
    bairro = db.Column(db.String(100), nullable=True)
    numero = db.Column(db.String(10), nullable=True)
    cidade = db.Column(db.String(100), nullable=True)
    estado = db.Column(db.String(2), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'nome': self.nome,
            'telefone': self.telefone,
            'email': self.email,
            'cep': self.cep,
            'rua': self.rua,
            'bairro': self.bairro,
            'numero': self.numero,
            'cidade': self.cidade,
            'estado': self.estado,
        }
