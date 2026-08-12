from database.db import db
from models.agendamento_model import Agendamento
from models.paciente_model import Paciente
from models.dentista_model import Dentista
from models.consulta_model import Consulta
from models.clinica_model import Clinica
from datetime import datetime, timedelta


def _validar_fks(data):
    """Verifica se os IDs referenciados existem no banco antes de inserir."""
    if not db.session.get(Paciente, data['paciente_id']):
        raise ValueError(f"Paciente {data['paciente_id']} não encontrado")
    if not db.session.get(Dentista, data['dentista_id']):
        raise ValueError(f"Dentista {data['dentista_id']} não encontrado")
    if not db.session.get(Consulta, data['consulta_id']):
        raise ValueError(f"Consulta {data['consulta_id']} não encontrada")
    if not db.session.get(Clinica, data['clinica_id']):
        raise ValueError(f"Clínica {data['clinica_id']} não encontrada")


def criar_agendamento(data):
    campos_obrigatorios = ['paciente_id', 'dentista_id', 'consulta_id', 'clinica_id', 'data_hora']
    for campo in campos_obrigatorios:
        if data.get(campo) is None:
            raise ValueError(f'Campo obrigatório ausente: {campo}')

    # Parse de data_hora — ISO 8601: "2025-08-15T14:00:00"
    try:
        data_hora = datetime.fromisoformat(str(data['data_hora']).replace('Z', ''))
    except (ValueError, TypeError):
        raise ValueError('Formato de data_hora inválido. Use ISO 8601: "2025-08-15T14:00:00"')

    if data_hora < datetime.now():
        raise ValueError('Não é possível agendar em uma data/hora no passado')

    # Valida que os IDs existem (FK explícita — SQLite pode não barrar sozinho)
    _validar_fks(data)

    # Verifica conflito de horário usando range de ±1 minuto para evitar problemas de precisão DateTime
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
        paciente_id=data['paciente_id'],
        dentista_id=data['dentista_id'],
        consulta_id=data['consulta_id'],
        clinica_id=data['clinica_id'],
        data_hora=data_hora,
        status='agendado',
    )
    db.session.add(agendamento)
    db.session.commit()
    return agendamento


def listar_agendamentos(paciente_id=None, dentista_id=None):
    """Sempre filtra — sem filtro retorna vazio para não expor dados de todos."""
    if paciente_id:
        return Agendamento.query.filter_by(paciente_id=paciente_id).all()
    if dentista_id:
        return Agendamento.query.filter_by(dentista_id=dentista_id).all()
    return []


def buscar_agendamento(id):
    return db.get_or_404(Agendamento, id)


def atualizar_status(id, novo_status):
    """Só altera o status — não permite trocar paciente, dentista ou clínica."""
    status_validos = ['agendado', 'concluido', 'cancelado']
    if novo_status not in status_validos:
        raise ValueError(f'Status inválido. Use: {status_validos}')

    agendamento = db.get_or_404(Agendamento, id)

    if agendamento.status == 'concluido':
        raise ValueError('Não é possível alterar um agendamento já concluído')

    agendamento.status = novo_status
    db.session.commit()
    return agendamento


def deletar_agendamento(id):
    agendamento = db.get_or_404(Agendamento, id)
    db.session.delete(agendamento)
    db.session.commit()
