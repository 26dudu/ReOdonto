from database.db import db

# Duração assumida quando o agendamento não informa uma. Usada na checagem
# de conflito de horário e no cálculo de ocupação do painel.
DURACAO_PADRAO_MINUTOS = 30


class Agendamento(db.Model):
    __tablename__ = 'agendamento'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    dentista_id = db.Column(db.Integer, db.ForeignKey('dentista.id'), nullable=False)
    clinica_id = db.Column(db.Integer, db.ForeignKey('clinica.id'), nullable=True)
    consulta_customizada = db.Column(db.String(200), nullable=True)  # tipo livre
    nome_paciente = db.Column(db.String(100), nullable=True)          # walk-in
    telefone_paciente = db.Column(db.String(20), nullable=True)       # walk-in
    data_hora = db.Column(db.DateTime, nullable=False)
    # Quanto tempo o horário ocupa na agenda — base da checagem de conflito.
    duracao_minutos = db.Column(
        db.Integer, nullable=False, default=DURACAO_PADRAO_MINUTOS
    )
    # Quanto o horário vale, em R$. Alimenta o "prejuízo evitado" do painel e
    # o campo `preco` que o app já esperava em consulta_valor.
    valor = db.Column(db.Float, nullable=True)
    # True quando o horário estava vago e foi preenchido por um encaixe —
    # é o que o painel conta como horário recuperado.
    encaixe = db.Column(db.Boolean, nullable=False, default=False)
    status = db.Column(db.String(20), nullable=False, default='agendado')
    # status possíveis: 'agendado', 'concluido', 'cancelado'

    # Relacionamentos
    dentista = db.relationship('Dentista', backref='agendamentos')
    clinica = db.relationship('Clinica', backref='agendamentos')

    @property
    def vago(self) -> bool:
        """Horário aberto na agenda: existe, mas ninguém foi marcado nele."""
        return self.nome_paciente is None

    @property
    def duracao(self) -> int:
        """Duração em minutos, caindo no padrão quando a coluna está vazia."""
        return self.duracao_minutos or DURACAO_PADRAO_MINUTOS

    def to_dict(self):
        return {
            'id': self.id,
            'dentista_id': self.dentista_id,
            'clinica_id': self.clinica_id,
            'consulta_customizada': self.consulta_customizada,
            'nome_paciente': self.nome_paciente,
            'telefone_paciente': self.telefone_paciente,
            'data_hora': self.data_hora.isoformat(),
            'duracao_minutos': self.duracao,
            'valor': self.valor,
            'encaixe': self.encaixe,
            'vago': self.vago,
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
            'consulta_valor': self.valor,
            'paciente_nome': self.nome_paciente,
            'telefone_paciente': self.telefone_paciente,
            'data_hora': self.data_hora.isoformat(),
            'duracao_minutos': self.duracao,
            'valor': self.valor,
            'encaixe': self.encaixe,
            'vago': self.vago,
            'status': self.status,
        }
