from datetime import datetime, timedelta

from database.db import db
from models.agendamento_model import Agendamento, DURACAO_PADRAO_MINUTOS
from models.dentista_model import Dentista
from models.clinica_model import Clinica

STATUS_VALIDOS = ('agendado', 'concluido', 'cancelado')


def _ler_data_hora(valor):
    """Converte o campo data_hora (ISO 8601) em datetime."""
    try:
        return datetime.fromisoformat(str(valor).replace('Z', ''))
    except (ValueError, TypeError):
        raise ValueError(
            'Formato de data_hora inválido. Use ISO 8601: "2025-08-15T14:00:00"'
        )


def _ler_duracao(valor):
    """Converte duracao_minutos, caindo no padrão quando não vem informado."""
    if valor in (None, ''):
        return DURACAO_PADRAO_MINUTOS
    try:
        duracao = int(valor)
    except (TypeError, ValueError):
        raise ValueError('duracao_minutos deve ser um número inteiro de minutos')
    if duracao <= 0:
        raise ValueError('duracao_minutos deve ser maior que zero')
    return duracao


def _ler_valor(valor):
    """Converte o valor em R$ do horário, que é opcional."""
    if valor in (None, ''):
        return None
    try:
        convertido = float(valor)
    except (TypeError, ValueError):
        raise ValueError('valor deve ser um número')
    if convertido < 0:
        raise ValueError('valor não pode ser negativo')
    return convertido


def conflito_de_horario(dentista_id, inicio, duracao_minutos, ignorar_id=None):
    """
    Devolve o agendamento que se sobrepõe ao intervalo informado, ou None.

    Antes a checagem só olhava o mesmo minuto (uma janela de ±59 segundos),
    então marcar 14:00 e 14:15 passava como se não houvesse conflito nenhum.
    Agora dois agendamentos conflitam quando os intervalos
    [início, início + duração) se cruzam.

    O filtro no banco corta os que começam depois do fim do novo intervalo; a
    comparação do fim de cada candidato é feita em Python porque somar a
    duração a uma data não é portável em SQL no SQLite.
    """
    fim = inicio + timedelta(minutes=duracao_minutos)

    candidatos = Agendamento.query.filter(
        Agendamento.dentista_id == dentista_id,
        Agendamento.status == 'agendado',
        Agendamento.data_hora < fim,
    )
    if ignorar_id is not None:
        candidatos = candidatos.filter(Agendamento.id != ignorar_id)

    for existente in candidatos.all():
        duracao_existente = existente.duracao_minutos or DURACAO_PADRAO_MINUTOS
        if existente.data_hora + timedelta(minutes=duracao_existente) > inicio:
            return existente
    return None


def criar_agendamento(data):
    """
    Cria um agendamento ou um horário vago.

    Obrigatórios: dentista_id, data_hora
    Opcionais: clinica_id, consulta_customizada, duracao_minutos, valor,
               nome_paciente, telefone_paciente

    Sem nome_paciente o registro é um horário vago: um espaço aberto na
    agenda, que o dentista preenche depois com um encaixe.
    """
    if not data.get('dentista_id'):
        raise ValueError('Campo obrigatório ausente: dentista_id')
    if not data.get('data_hora'):
        raise ValueError('Campo obrigatório ausente: data_hora')

    if not db.session.get(Dentista, data['dentista_id']):
        raise ValueError(f"Dentista {data['dentista_id']} não encontrado")

    clinica_id = data.get('clinica_id')
    if clinica_id and not db.session.get(Clinica, clinica_id):
        raise ValueError(f"Clínica {clinica_id} não encontrada")

    data_hora = _ler_data_hora(data['data_hora'])
    duracao = _ler_duracao(data.get('duracao_minutos'))
    valor = _ler_valor(data.get('valor'))

    conflito = conflito_de_horario(data['dentista_id'], data_hora, duracao)
    if conflito:
        if conflito.nome_paciente:
            raise ValueError(
                'O dentista já tem um agendamento que ocupa esse horário'
            )
        raise ValueError(
            'Esse horário já está aberto na agenda — use o encaixe rápido '
            'para preencher o horário vago'
        )

    nome_paciente = (data.get('nome_paciente') or '').strip() or None
    telefone_paciente = (data.get('telefone_paciente') or '').strip() or None

    agendamento = Agendamento(
        dentista_id=data['dentista_id'],
        clinica_id=clinica_id,
        consulta_customizada=data.get('consulta_customizada'),
        nome_paciente=nome_paciente,
        telefone_paciente=telefone_paciente,
        data_hora=data_hora,
        duracao_minutos=duracao,
        valor=valor,
        encaixe=False,
        status='agendado',
    )
    db.session.add(agendamento)
    db.session.commit()
    return agendamento


def listar_agendamentos(dentista_id=None):
    """
    Lista os agendamentos do dentista, incluindo os horários vagos.

    Os cancelados ficam de fora da agenda — eles continuam no banco porque o
    painel usa a contagem de cancelamentos, mas o que o dentista vê no lugar
    de um cancelamento é o horário vago aberto por ele.
    """
    if not dentista_id:
        return []
    return (
        Agendamento.query
        .filter_by(dentista_id=dentista_id)
        .filter(Agendamento.status != 'cancelado')
        .order_by(Agendamento.data_hora)
        .all()
    )


def buscar_agendamento(id):
    return db.get_or_404(Agendamento, id)


def _abrir_horario_vago(cancelado):
    """
    Abre um horário vago no lugar de um agendamento cancelado.

    É o elo que faltava no ciclo de realocação: antes, cancelar apenas tirava
    o horário da tela, e o horário vago que o app existe para reaproveitar
    nunca aparecia. O registro cancelado é preservado (o painel conta os
    cancelamentos) e um novo registro sem paciente ocupa o mesmo horário.

    O valor e a duração são herdados — é o que o horário valia e vale de novo
    se alguém for encaixado nele. O tipo de consulta é limpo, porque quem
    ocupar o horário pode precisar de outro procedimento.
    """
    ja_aberto = Agendamento.query.filter(
        Agendamento.dentista_id == cancelado.dentista_id,
        Agendamento.data_hora == cancelado.data_hora,
        Agendamento.nome_paciente.is_(None),
        Agendamento.status == 'agendado',
    ).first()
    if ja_aberto:
        return ja_aberto

    vago = Agendamento(
        dentista_id=cancelado.dentista_id,
        clinica_id=cancelado.clinica_id,
        consulta_customizada=None,
        nome_paciente=None,
        telefone_paciente=None,
        data_hora=cancelado.data_hora,
        duracao_minutos=cancelado.duracao,
        valor=cancelado.valor,
        encaixe=False,
        status='agendado',
    )
    db.session.add(vago)
    return vago


def atualizar_status(id, novo_status):
    """
    Troca o status do agendamento.

    Devolve (agendamento, horario_vago). O horario_vago vem preenchido quando
    o cancelamento abriu um horário novo na agenda, e é None nos outros casos.
    """
    if novo_status not in STATUS_VALIDOS:
        raise ValueError(f'Status inválido. Use: {list(STATUS_VALIDOS)}')

    agendamento = db.get_or_404(Agendamento, id)

    if agendamento.status == 'concluido':
        raise ValueError('Não é possível alterar um agendamento já concluído')

    if novo_status == 'concluido' and agendamento.vago:
        raise ValueError('Não é possível concluir um horário vago')

    agendamento.status = novo_status

    # Cancelar um horário que já estava vago só fecha o horário: o dentista
    # está bloqueando o tempo, não abrindo espaço.
    horario_vago = None
    if novo_status == 'cancelado' and not agendamento.vago:
        horario_vago = _abrir_horario_vago(agendamento)

    db.session.commit()
    return agendamento, horario_vago


def preencher_paciente(id, nome, telefone, consulta_customizada=None):
    """
    Encaixa um paciente em um horário vago.

    É o fecho do ciclo: o horário foi aberto por um cancelamento e volta a
    ser atendimento. Marca `encaixe` para o painel contar como horário
    recuperado.
    """
    agendamento = db.get_or_404(Agendamento, id)

    if agendamento.status == 'cancelado':
        raise ValueError('Esse horário foi cancelado')
    if agendamento.status == 'concluido':
        raise ValueError('Esse horário já foi concluído')
    if not agendamento.vago:
        raise ValueError(
            f'Esse horário já está com {agendamento.nome_paciente}'
        )

    agendamento.nome_paciente = nome
    agendamento.telefone_paciente = telefone or None
    if consulta_customizada:
        agendamento.consulta_customizada = consulta_customizada
    agendamento.status = 'agendado'
    agendamento.encaixe = True
    db.session.commit()
    return agendamento


def deletar_agendamento(id):
    agendamento = db.get_or_404(Agendamento, id)
    db.session.delete(agendamento)
    db.session.commit()
