from database.db import db
from utils.crypto import decrypt_data


class Paciente(db.Model):
    __tablename__ = 'paciente'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.Text, nullable=False)  # Encrypted
    email = db.Column(db.Text, nullable=False)  # Encrypted
    email_hash = db.Column(db.String(64), nullable=False, unique=True)  # SHA-256 hash for queries
    senha = db.Column(db.String(255), nullable=False)
    telefone = db.Column(db.Text, nullable=True)  # Encrypted
    cpf = db.Column(db.Text, nullable=True)  # Encrypted
    cpf_hash = db.Column(db.String(64), nullable=True, unique=True)  # SHA-256 hash for queries
    cep = db.Column(db.Text, nullable=True)  # Encrypted
    rua = db.Column(db.Text, nullable=True)  # Encrypted
    bairro = db.Column(db.Text, nullable=True)  # Encrypted
    numero = db.Column(db.Text, nullable=True)  # Encrypted

    def to_dict(self):
        return {
            'id': self.id,
            'nome': decrypt_data(self.nome),
            'email': decrypt_data(self.email),
            'telefone': decrypt_data(self.telefone),
            'cpf': decrypt_data(self.cpf),
            'cep': decrypt_data(self.cep),
            'rua': decrypt_data(self.rua),
            'bairro': decrypt_data(self.bairro),
            'numero': decrypt_data(self.numero),
        }
