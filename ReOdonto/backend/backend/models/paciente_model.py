from database.db import db

class Paciente(db.Model):
    __tablename__ = 'paciente'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nome = db.Column(db.String(100), nullable=False)

    def to_dict(self):
        return {'id': self.id, 'nome': self.nome}
