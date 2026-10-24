from database.db import db


class Agendamento(db.Model):
    __tablename__ = 'agendamento'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    dentista_id = db.Column(db.Integer, db.ForeignKey('dentista.id'), nullable=False)
    clinica_id = db.Column(db.Integer, db.ForeignKey('clinica.id'), nullable=True)
    consulta_customizada = db.Column(db.String(200), nullable=True)  # tipo livre
    nome_paciente = db.Column(db.String(100), nullable=True)          # walk-in
    telefone_paciente = db.Column(db.String(20), nullable=True)       # walk-in
    data_hora = db.Column(db.DateTime, nullable=False)
    status = db.Column(db.String(20), nullable=False, default='agendado')
    # status possíveis: 'agendado', 'concluido', 'cancelado'

    # Relacionamentos
    dentista = db.relationship('Dentista', backref='agendamentos')
    clinica = db.relationship('Clinica', backref='agendamentos')

    def to_dict(self):
        return {
            'id': self.id,
            'dentista_id': self.dentista_id,
            'clinica_id': self.clinica_id,
            'consulta_customizada': self.consulta_customizada,
            'nome_paciente': self.nome_paciente,
            'telefone_paciente': self.telefone_paciente,
            'data_hora': self.data_hora.isoformat(),
            'status': self.status,
        }

    def to_dict_completo(self):
        """Inclui nomes dos relacionamentos — evita múltiplas chamadas do Flutter."""
        return {
            'id': self.id,
            'dentista_id': self.dentista_id,
            'dentista_nome': self.dentista.nome if self.dentista else None,
            'clinica_id': self.clinica_id,
            'clinica_nome': self.clinica.nome if self.clinica else None,
            'clinica_endereco': (
                f"{self.clinica.rua}, {self.clinica.numero} — {self.clinica.bairro}"
                if self.clinica and self.clinica.rua else None
            ),
            'consulta_nome': self.consulta_customizada,
            'consulta_customizada': self.consulta_customizada,
            'paciente_nome': self.nome_paciente,
            'telefone_paciente': self.telefone_paciente,
            'data_hora': self.data_hora.isoformat(),
            'status': self.status,
        }
