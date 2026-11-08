from database.db import db
from models.agendamento_model import Agendamento


def buscar_ou_404(id):
    return db.get_or_404(Agendamento, id)


def listar_agendados_ate(dentista_id, fim, ignorar_id=None):
    consulta = Agendamento.query.filter(
        Agendamento.dentista_id == dentista_id,
        Agendamento.status == 'agendado',
        Agendamento.data_hora < fim,
    )
    if ignorar_id is not None:
        consulta = consulta.filter(Agendamento.id != ignorar_id)
    return consulta.all()


def listar_agenda(dentista_id):
    return (
        Agendamento.query
        .filter_by(dentista_id=dentista_id)
        .filter(Agendamento.status != 'cancelado')
        .order_by(Agendamento.data_hora)
        .all()
    )


def listar_desde(dentista_id, inicio):
    return Agendamento.query.filter(
        Agendamento.dentista_id == dentista_id,
        Agendamento.data_hora >= inicio,
    ).all()


def buscar_vago_aberto(dentista_id, data_hora):
    return Agendamento.query.filter(
        Agendamento.dentista_id == dentista_id,
        Agendamento.data_hora == data_hora,
        Agendamento.nome_paciente.is_(None),
        Agendamento.status == 'agendado',
    ).first()


def buscar_por_id(id):
    return db.session.get(Agendamento, id)


def listar_agendados_entre(dentista_id, depois_de, ate):
    return (
        Agendamento.query
        .filter(
            Agendamento.dentista_id == dentista_id,
            Agendamento.status == 'agendado',
            Agendamento.nome_paciente.isnot(None),
            Agendamento.data_hora > depois_de,
            Agendamento.data_hora <= ate,
        )
        .order_by(Agendamento.data_hora)
        .all()
    )


def listar_cancelados_em(dentista_id, data_hora):
    return Agendamento.query.filter(
        Agendamento.dentista_id == dentista_id,
        Agendamento.status == 'cancelado',
        Agendamento.nome_paciente.isnot(None),
        Agendamento.data_hora == data_hora,
    ).all()


def listar_agendados_futuros(dentista_id, agora):
    return (
        Agendamento.query
        .filter(
            Agendamento.dentista_id == dentista_id,
            Agendamento.status == 'agendado',
            Agendamento.nome_paciente.isnot(None),
            Agendamento.data_hora >= agora,
        )
        .order_by(Agendamento.data_hora)
        .all()
    )


def listar_vagos_futuros(dentista_id, agora):
    return (
        Agendamento.query
        .filter(
            Agendamento.dentista_id == dentista_id,
            Agendamento.status == 'agendado',
            Agendamento.nome_paciente.is_(None),
            Agendamento.data_hora >= agora,
        )
        .order_by(Agendamento.data_hora)
        .all()
    )


def adicionar(agendamento):
    db.session.add(agendamento)


def remover(agendamento):
    db.session.delete(agendamento)


def remover_do_dentista(dentista_id):
    Agendamento.query.filter_by(dentista_id=dentista_id).delete(
        synchronize_session=False
    )


def confirmar():
    db.session.commit()
