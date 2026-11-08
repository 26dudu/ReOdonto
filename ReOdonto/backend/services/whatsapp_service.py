import re
from datetime import datetime, timedelta

from repositories import agendamento_repository, dentista_repository
from services import agendamento_service

DURACAO_WHATSAPP_MINUTOS = 15
PASSO_MINUTOS = 15
HORA_ABERTURA = 8
HORA_FECHAMENTO = 18
MAX_SUGESTOES = 3
JANELA_BUSCA_DIAS = 14

ROTULOS_FALTANDO = {
    'nome_paciente': 'seu nome',
    'consulta_customizada': 'o tipo de atendimento (por exemplo: limpeza, clareamento ou avaliação)',
    'data_hora': 'o dia e o horário que você prefere',
}


def _texto_faltando(faltando):
    itens = [ROTULOS_FALTANDO.get(campo, campo) for campo in faltando]
    if len(itens) == 1:
        lista = itens[0]
    else:
        lista = ', '.join(itens[:-1]) + ' e ' + itens[-1]
    return f'Para agendar, ainda preciso de: {lista}.'


def _resposta(status, mensagem, **extra):
    return {'status': status, 'mensagem': mensagem, **extra}


def _livre(dentista_id, inicio, duracao):
    conflito = agendamento_service.conflito_de_horario(dentista_id, inicio, duracao)
    return conflito is None or (conflito.vago and conflito.data_hora == inicio)


def _no_expediente(inicio, duracao):
    if inicio.weekday() == 6:
        return False
    abre = inicio.replace(hour=HORA_ABERTURA, minute=0, second=0, microsecond=0)
    fecha = inicio.replace(hour=HORA_FECHAMENTO, minute=0, second=0, microsecond=0)
    return abre <= inicio and inicio + timedelta(minutes=duracao) <= fecha


def _sugerir(dentista_id, referencia, duracao, agora):
    sugestoes = []
    passos = JANELA_BUSCA_DIAS * 24 * 60 // PASSO_MINUTOS
    for k in range(0, passos + 1):
        for sinal in ((1,) if k == 0 else (1, -1)):
            candidato = referencia + timedelta(minutes=PASSO_MINUTOS * k * sinal)
            if candidato <= agora or not _no_expediente(candidato, duracao):
                continue
            if _livre(dentista_id, candidato, duracao):
                sugestoes.append(candidato)
                if len(sugestoes) == MAX_SUGESTOES:
                    return sorted(sugestoes)
    return sorted(sugestoes)


def _rotulo(horario, referencia):
    if horario.date() == referencia.date():
        return horario.strftime('%H:%M')
    return horario.strftime('%d/%m às %H:%M')


def _texto_sugestoes(sugestoes, referencia):
    rotulos = [_rotulo(s, referencia) for s in sugestoes]
    if len(rotulos) == 1:
        return rotulos[0]
    return ', '.join(rotulos[:-1]) + ' e ' + rotulos[-1]


def _alternativas(sugestoes):
    return [{'data_hora': s.isoformat()} for s in sugestoes]


def agendar(data):
    dentista_id = data.get('dentista_id')
    nome = (data.get('nome_paciente') or '').strip()
    telefone = (data.get('telefone_paciente') or '').strip()
    tipo = (data.get('consulta_customizada') or '').strip()
    faltando = [
        campo for campo, valor in (
            ('dentista_id', dentista_id),
            ('nome_paciente', nome),
            ('consulta_customizada', tipo),
            ('data_hora', data.get('data_hora')),
        ) if not valor
    ]
    if faltando:
        return _resposta('dados_incompletos', _texto_faltando(faltando), faltando=faltando)

    dentista = dentista_repository.buscar_por_id(dentista_id)
    if not dentista:
        raise ValueError(f'Dentista {dentista_id} não encontrado')

    data_hora = agendamento_service._ler_data_hora(data['data_hora'])
    duracao = agendamento_service._ler_duracao(
        data.get('duracao_minutos') or DURACAO_WHATSAPP_MINUTOS
    )
    agora = datetime.now()

    if data_hora <= agora:
        sugestoes = _sugerir(dentista_id, agora, duracao, agora)
        if sugestoes:
            mensagem = (
                'Esse horário já passou. Os próximos horários livres são: '
                f'{_texto_sugestoes(sugestoes, agora)}. Qual você prefere?'
            )
        else:
            mensagem = 'Esse horário já passou. Pode me informar outra data e hora?'
        return _resposta('data_invalida', mensagem, alternativas=_alternativas(sugestoes))

    conflito = agendamento_service.conflito_de_horario(
        dentista_id, data_hora, duracao
    )

    if conflito is None:
        agendamento = agendamento_service.criar_agendamento({
            'dentista_id': dentista_id,
            'data_hora': data_hora.isoformat(),
            'duracao_minutos': duracao,
            'valor': data.get('valor'),
            'consulta_customizada': tipo,
            'nome_paciente': nome,
            'telefone_paciente': telefone,
        })
        return _resposta(
            'confirmado',
            f'Consulta confirmada para {data_hora.strftime("%d/%m às %H:%M")} com {dentista.nome}.',
            agendamento=agendamento.to_dict_completo(),
        )

    if conflito.vago and conflito.data_hora == data_hora:
        agendamento = agendamento_service.preencher_paciente(
            conflito.id, nome, telefone, tipo
        )
        return _resposta(
            'encaixado',
            f'Consulta confirmada para {data_hora.strftime("%d/%m às %H:%M")} com {dentista.nome}.',
            agendamento=agendamento.to_dict_completo(),
        )

    sugestoes = _sugerir(dentista_id, data_hora, duracao, agora)
    if sugestoes:
        mensagem = (
            f'Esse horário não está disponível. Os horários livres mais próximos são: '
            f'{_texto_sugestoes(sugestoes, data_hora)}. Qual você prefere?'
        )
    else:
        mensagem = (
            'Esse horário não está disponível e não encontrei vagas nos próximos dias. '
            'Pode sugerir outra data?'
        )
    return _resposta('conflito', mensagem, alternativas=_alternativas(sugestoes))


def _chave_telefone(numero):
    digitos = re.sub(r'\D', '', numero or '')
    if digitos.startswith('55') and len(digitos) > 11:
        digitos = digitos[2:]
    if len(digitos) < 10:
        return ''
    return digitos[:2] + digitos[-8:]


def _lista_de_horarios(agendamentos):
    rotulos = [a.data_hora.strftime('%d/%m às %H:%M') for a in agendamentos]
    if len(rotulos) == 1:
        return rotulos[0]
    return ', '.join(rotulos[:-1]) + ' e ' + rotulos[-1]


def cancelar(data):
    dentista_id = data.get('dentista_id')
    chave = _chave_telefone(data.get('telefone_paciente'))
    if not dentista_id or not chave:
        raise ValueError('dentista_id e telefone_paciente são obrigatórios')

    if not dentista_repository.buscar_por_id(dentista_id):
        raise ValueError(f'Dentista {dentista_id} não encontrado')

    agora = datetime.now()
    minhas = [
        a for a in agendamento_repository.listar_agendados_futuros(dentista_id, agora)
        if _chave_telefone(a.telefone_paciente) == chave
    ]
    if not minhas:
        return _resposta(
            'nao_encontrado',
            'Não encontrei nenhuma consulta agendada para o seu número.',
        )

    alvo = minhas[0] if len(minhas) == 1 else None
    if alvo is None and data.get('data_hora'):
        pedido = agendamento_service._ler_data_hora(data['data_hora'])
        alvo = next((a for a in minhas if a.data_hora == pedido), None)

    if alvo is None:
        return _resposta(
            'escolher',
            f'Você tem mais de uma consulta agendada: {_lista_de_horarios(minhas)}. '
            'Me diga o dia e o horário da que você quer cancelar.',
            consultas=[{'id': a.id, 'data_hora': a.data_hora.isoformat()} for a in minhas],
        )

    agendamento, horario_liberado = agendamento_service.atualizar_status(alvo.id, 'cancelado')
    return _resposta(
        'cancelado',
        f'Sua consulta de {agendamento.data_hora.strftime("%d/%m às %H:%M")} foi cancelada. '
        'Quando quiser remarcar, é só me dizer o dia e o horário.',
        agendamento=agendamento.to_dict_completo(),
    )
