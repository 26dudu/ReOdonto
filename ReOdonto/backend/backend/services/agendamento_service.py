from database.db import db
from models.agendamento_model import Agendamento
from datetime import datetime

def criar_agendamento(data):
    agendamento = Agendamento(
        paciente_id=data['paciente_id'],
        dentista_id=data['dentista_id'],
        consulta_id=data['consulta_id'],
        clinica_id=data['clinica_id'],
        data=datetime.fromisoformat(data['data']),
        horario=datetime.fromisoformat(data['horario'])
    )
    db.session.add(agendamento)
    db.session.commit()
    return agendamento

def listar_agendamentos():
    return Agendamento.query.all()

def buscar_agendamento(id):
    return Agendamento.query.get_or_404(id)

def atualizar_agendamento(id, data):
    agendamento = Agendamento.query.get_or_404(id)
    agendamento.paciente_id = data['paciente_id']
    agendamento.dentista_id = data['dentista_id']
    agendamento.consulta_id = data['consulta_id']
    agendamento.clinica_id = data['clinica_id']
    agendamento.data = datetime.fromisoformat(data['data'])
    agendamento.horario = datetime.fromisoformat(data['horario'])
    db.session.commit()
    return agendamento

def deletar_agendamento(id):
    agendamento = Agendamento.query.get_or_404(id)
    db.session.delete(agendamento)
    db.session.commit()
