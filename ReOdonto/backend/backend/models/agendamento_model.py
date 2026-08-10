from database.db import db

class Agendamento(db.Model):
    __tablename__ = 'agendamento'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('paciente.id'), nullable=False)
    dentista_id = db.Column(db.Integer, db.ForeignKey('dentista.id'), nullable=False)
    consulta_id = db.Column(db.Integer, db.ForeignKey('consulta.id'), nullable=False)
    clinica_id = db.Column(db.Integer, db.ForeignKey('clinica.id'), nullable=False)
    data = db.Column(db.DateTime, nullable=False)
    horario = db.Column(db.DateTime, nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'paciente_id': self.paciente_id,
            'dentista_id': self.dentista_id,
            'consulta_id': self.consulta_id,
            'clinica_id': self.clinica_id,
            'data': self.data.isoformat(),
            'horario': self.horario.isoformat()
        }
