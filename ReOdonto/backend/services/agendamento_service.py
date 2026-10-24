from database.db import db
from models.agendamento_model import Agendamento
from models.dentista_model import Dentista
from models.clinica_model import Clinica
from datetime import datetime, timedelta


def criar_agendamento(data):
    """
    Cria um novo agendamento.

    Campos obrigatórios: dentista_id, data_hora
    Opcionais: clinica_id, consulta_customizada,
               nome_paciente, telefone_paciente
    """
    if not data.get('dentista_id'):
        raise ValueError('Campo obrigatório ausente: dentista_id')
    if not data.get('data_hora'):
        raise ValueError('Campo obrigatório ausente: data_hora')

    # Valida dentista
    if not db.session.get(Dentista, data['dentista_id']):
        raise ValueError(f"Dentista {data['dentista_id']} não encontrado")

    # Valida clínica (se fornecida)
    clinica_id = data.get('clinica_id')
    if clinica_id and not db.session.get(Clinica, clinica_id):
        raise ValueError(f"Clínica {clinica_id} não encontrada")

    # Parse de data_hora — ISO 8601: "2025-08-15T14:00:00"
    try:
        data_hora = datetime.fromisoformat(str(data['data_hora']).replace('Z', ''))
    except (ValueError, TypeError):
        raise ValueError('Formato de data_hora inválido. Use ISO 8601: "2025-08-15T14:00:00"')

    # Verifica conflito de horário para o mesmo dentista
    janela_inicio = data_hora - timedelta(seconds=59)
    janela_fim = data_hora + timedelta(seconds=59)
    conflito = Agendamento.query.filter(
        Agendamento.dentista_id == data['dentista_id'],
        Agendamento.data_hora >= janela_inicio,
        Agendamento.data_hora <= janela_fim,
        Agendamento.status == 'agendado',
    ).first()
    if conflito:
        raise ValueError('O dentista já possui um agendamento nesse horário')

    agendamento = Agendamento(
        dentista_id=data['dentista_id'],
        clinica_id=clinica_id,
        consulta_customizada=data.get('consulta_customizada'),
        nome_paciente=data.get('nome_paciente'),
        telefone_paciente=data.get('telefone_paciente'),
        data_hora=data_hora,
        status='agendado',
    )
    db.session.add(agendamento)
    db.session.commit()
    return agendamento


def listar_agendamentos(dentista_id=None):
    """Lista agendamentos do dentista — exclui cancelados."""
    if dentista_id:
        return (
            Agendamento.query
            .filter_by(dentista_id=dentista_id)
            .filter(Agendamento.status != 'cancelado')
            .order_by(Agendamento.data_hora)
            .all()
        )
    return []


def buscar_agendamento(id):
    return db.get_or_404(Agendamento, id)


def atualizar_status(id, novo_status):
    status_validos = ['agendado', 'concluido', 'cancelado']
    if novo_status not in status_validos:
        raise ValueError(f'Status inválido. Use: {status_validos}')

    agendamento = db.get_or_404(Agendamento, id)

    if agendamento.status == 'concluido':
        raise ValueError('Não é possível alterar um agendamento já concluído')

    agendamento.status = novo_status
    db.session.commit()
    return agendamento


def preencher_paciente(id, nome, telefone):
    """Preenche nome e telefone de um agendamento vago (walk-in)."""
    agendamento = db.get_or_404(Agendamento, id)
    agendamento.nome_paciente = nome
    agendamento.telefone_paciente = telefone
    agendamento.status = 'agendado'
    db.session.commit()
    return agendamento


def deletar_agendamento(id):
    agendamento = db.get_or_404(Agendamento, id)
    db.session.delete(agendamento)
    db.session.commit()
