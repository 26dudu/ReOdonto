from database.db import db


class Paciente(db.Model):
    __tablename__ = 'paciente'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(150), nullable=False, unique=True)
    senha = db.Column(db.String(255), nullable=False)
    telefone = db.Column(db.String(20), nullable=True)
    cpf = db.Column(db.String(14), nullable=True, unique=True)
    cep = db.Column(db.String(9), nullable=True)
    rua = db.Column(db.String(150), nullable=True)
    bairro = db.Column(db.String(100), nullable=True)
    numero = db.Column(db.String(10), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'nome': self.nome,
            'email': self.email,
            'telefone': self.telefone,
            'cpf': self.cpf,
            'cep': self.cep,
            'rua': self.rua,
            'bairro': self.bairro,
            'numero': self.numero,
        }
