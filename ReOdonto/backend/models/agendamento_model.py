from database.db import db


class Agendamento(db.Model):
    __tablename__ = 'agendamento'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('paciente.id'), nullable=False)
    dentista_id = db.Column(db.Integer, db.ForeignKey('dentista.id'), nullable=False)
    consulta_id = db.Column(db.Integer, db.ForeignKey('consulta.id'), nullable=False)
    clinica_id = db.Column(db.Integer, db.ForeignKey('clinica.id'), nullable=False)
    data_hora = db.Column(db.DateTime, nullable=False)   # data e hora unificados
    status = db.Column(db.String(20), nullable=False, default='agendado')
    # status possíveis: 'agendado', 'concluido', 'cancelado'

    # Relacionamentos para facilitar joins depois
    paciente = db.relationship('Paciente', backref='agendamentos')
    dentista = db.relationship('Dentista', backref='agendamentos')
    consulta = db.relationship('Consulta', backref='agendamentos')
    clinica = db.relationship('Clinica', backref='agendamentos')

    def to_dict(self):
        return {
            'id': self.id,
            'paciente_id': self.paciente_id,
            'dentista_id': self.dentista_id,
            'consulta_id': self.consulta_id,
            'clinica_id': self.clinica_id,
            'data_hora': self.data_hora.isoformat(),
            'status': self.status,
        }

    def to_dict_completo(self):
        """Inclui nomes dos relacionamentos — evita múltiplas chamadas do Flutter."""
        return {
            'id': self.id,
            'paciente_id': self.paciente_id,
            'paciente_nome': self.paciente.nome if self.paciente else None,
            'dentista_id': self.dentista_id,
            'dentista_nome': self.dentista.nome if self.dentista else None,
            'consulta_id': self.consulta_id,
            'consulta_nome': self.consulta.nome if self.consulta else None,
            'consulta_valor': self.consulta.valor if self.consulta else None,
            'clinica_id': self.clinica_id,
            'clinica_nome': self.clinica.nome if self.clinica else None,
            'clinica_endereco': (
                f"{self.clinica.rua}, {self.clinica.numero} — {self.clinica.bairro}"
                if self.clinica and self.clinica.rua else None
            ),
            'data_hora': self.data_hora.isoformat(),
            'status': self.status,
        }
