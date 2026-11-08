import logging
from datetime import datetime, timedelta

from models.oferta_model import OfertaAdiantamento
from repositories import (
    agendamento_repository,
    dentista_repository,
    oferta_repository,
)
from services import agendamento_service, ponte_whatsapp
from utils.telefone import chave_telefone

logger = logging.getLogger(__name__)

VALIDADE_OFERTA_MINUTOS = 30
JANELA_DIAS = 7
MAX_RODADAS = 2


def _rotulo(momento):
    return momento.strftime('%d/%m às %H:%M')


def _primeiro_nome(nome):
    return (nome or '').strip().split(' ')[0] or 'paciente'


def _ja_ofertado(vago_id):
    return {o.agendamento_id for o in oferta_repository.listar_do_vago(vago_id)}


def _com_oferta_pendente(agendamento_id):
    agora = datetime.now()
    return any(
        not o.expirada(agora)
        for o in oferta_repository.listar_do_agendamento_pendentes(agendamento_id)
    )


def _proximo_candidato(vago):
    agora = datetime.now()
    excluidos = _ja_ofertado(vago.id)
    quem_cancelou = {
        chave_telefone(c.telefone_paciente)
        for c in agendamento_repository.listar_cancelados_em(vago.dentista_id, vago.data_hora)
    }
    ate = vago.data_hora + timedelta(days=JANELA_DIAS)
    candidatos = agendamento_repository.listar_agendados_entre(
        vago.dentista_id, vago.data_hora, ate
    )
    for candidato in candidatos:
        if candidato.id in excluidos or not chave_telefone(candidato.telefone_paciente):
            continue
        if chave_telefone(candidato.telefone_paciente) in quem_cancelou:
            continue
        if _com_oferta_pendente(candidato.id):
            continue
        if _cabe_no_vago(candidato, vago):
            return candidato
    return None


def _cabe_no_vago(agendamento, vago):
    inicio = vago.data_hora
    fim = inicio + timedelta(minutes=agendamento.duracao)
    for outro in agendamento_repository.listar_agendados_ate(
        agendamento.dentista_id, fim, ignorar_id=agendamento.id
    ):
        if outro.id == vago.id or outro.vago:
            continue
        if outro.data_hora + timedelta(minutes=outro.duracao) > inicio:
            return False
    return True


def oferecer(vago, rodada=1):
    try:
        if vago is None or rodada > MAX_RODADAS or not vago.vago:
            return None
        if vago.status != 'agendado' or vago.data_hora <= datetime.now():
            return None

        candidato = _proximo_candidato(vago)
        if candidato is None:
            return None

        dentista = dentista_repository.buscar_por_id(vago.dentista_id)
        oferta = OfertaAdiantamento(
            dentista_id=vago.dentista_id,
            vago_id=vago.id,
            agendamento_id=candidato.id,
            telefone=candidato.telefone_paciente,
            rodada=rodada,
            status='pendente',
            expira_em=datetime.now() + timedelta(minutes=VALIDADE_OFERTA_MINUTOS),
        )
        oferta_repository.adicionar(oferta)
        oferta_repository.confirmar()

        mensagem = (
            f'Olá, {_primeiro_nome(candidato.nome_paciente)}! Abriu um horário com '
            f'{dentista.nome} em {_rotulo(vago.data_hora)}. '
            f'Quer adiantar sua consulta de {_rotulo(candidato.data_hora)} para esse horário? '
            'Responda SIM para adiantar ou NÃO para manter o horário atual.'
        )
        ponte_whatsapp.notificar(candidato.telefone_paciente, mensagem)
        return oferta
    except Exception:
        logger.exception('Falha ao oferecer o horário vago')
        return None


def _resposta(status, mensagem, **extra):
    return {'status': status, 'mensagem': mensagem, **extra}


def _oferta_pendente_do_telefone(dentista_id, telefone):
    chave = chave_telefone(telefone)
    for oferta in oferta_repository.listar_pendentes_do_dentista(dentista_id):
        if chave_telefone(oferta.telefone) == chave:
            return oferta
    return None


def _encerrar_ofertas_do_vago(vago_id, exceto_id=None):
    for outra in oferta_repository.listar_do_vago(vago_id):
        if outra.status == 'pendente' and outra.id != exceto_id:
            outra.status = 'cancelada'


def responder(dentista_id, telefone, aceitou):
    oferta = _oferta_pendente_do_telefone(dentista_id, telefone)
    if oferta is None:
        return _resposta(
            'sem_oferta',
            'Não encontrei nenhuma oferta de adiantamento pendente para o seu número.',
        )

    agendamento = agendamento_repository.buscar_por_id(oferta.agendamento_id)
    vago = agendamento_repository.buscar_por_id(oferta.vago_id)

    if oferta.expirada():
        oferta.status = 'expirada'
        oferta_repository.confirmar()
        return _resposta(
            'oferta_expirada',
            'Essa oferta expirou. Sua consulta continua no horário original.',
        )

    if agendamento is None or agendamento.status != 'agendado':
        oferta.status = 'cancelada'
        oferta_repository.confirmar()
        return _resposta('sem_oferta', 'Não encontrei nenhuma oferta de adiantamento pendente para o seu número.')

    if not aceitou:
        oferta.status = 'recusada'
        oferta_repository.confirmar()
        oferecer(vago, oferta.rodada + 1)
        return _resposta(
            'oferta_recusada',
            f'Tudo bem! Sua consulta continua em {_rotulo(agendamento.data_hora)}.',
        )

    vago_valido = (
        vago is not None and vago.vago and vago.status == 'agendado'
        and vago.data_hora > datetime.now() and _cabe_no_vago(agendamento, vago)
    )
    if not vago_valido:
        oferta.status = 'cancelada'
        oferta_repository.confirmar()
        return _resposta(
            'oferta_indisponivel',
            'Esse horário já foi preenchido por outra pessoa. '
            f'Sua consulta continua em {_rotulo(agendamento.data_hora)}.',
        )

    novo_horario = vago.data_hora
    horario_liberado = agendamento_service._abrir_horario_vago(agendamento)
    agendamento.data_hora = novo_horario
    agendamento.encaixe = True
    agendamento_repository.remover(vago)
    oferta.status = 'aceita'
    _encerrar_ofertas_do_vago(vago.id, exceto_id=oferta.id)
    agendamento_repository.confirmar()

    oferecer(horario_liberado, oferta.rodada + 1)
    return _resposta(
        'adiantado',
        f'Pronto! Sua consulta foi adiantada para {_rotulo(novo_horario)}.',
        agendamento=agendamento.to_dict_completo(),
    )
