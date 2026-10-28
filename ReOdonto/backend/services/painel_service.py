"""
Números do Painel Administrativo (tela Menu do app).

O JSON devolvido aqui é exatamente o formato que ResumoPainel.fromJson já
esperava no Flutter — a tela mostrava tudo zerado porque este endpoint nunca
existiu. Todas as contas olham apenas a agenda do dentista informado.

Como cada indicador é calculado:
  prejuizo_evitado ....... soma do valor dos horários que estavam vagos e
                           foram preenchidos por encaixe
  ociosidade ............. % do tempo de agenda que ficou vago
  horarios_recuperados ... quantos horários vagos viraram atendimento
  pacientes_encaixados ... quantas pessoas diferentes ocuparam esses horários
  taxa_ocupacao .......... % do tempo de agenda que teve paciente
  desempenho ............. prejuízo evitado mês a mês, para o gráfico
"""
from datetime import datetime

from models.agendamento_model import Agendamento

MESES_ABREVIADOS = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
]

MESES_RESUMO = 3    # janela dos cartões e do "Resumo dos últimos 3 meses"
MESES_GRAFICO = 6   # barras do gráfico "Desempenho dos últimos meses"


def _inicio_do_mes(referencia: datetime, meses_atras: int = 0) -> datetime:
    """
    Primeiro instante do mês deslocado `meses_atras` em relação à referência.

    Aceita deslocamento negativo, que anda para a frente no calendário — é
    assim que se obtém o limite superior do mês mais recente do gráfico.
    """
    ano = referencia.year
    mes = referencia.month - meses_atras
    while mes <= 0:
        mes += 12
        ano -= 1
    while mes > 12:
        mes -= 12
        ano += 1
    return datetime(ano, mes, 1)


def _e_encaixe(agendamento) -> bool:
    """Horário vago que virou atendimento e não foi cancelado depois."""
    return bool(agendamento.encaixe) and agendamento.status != 'cancelado'


def _desempenho_por_mes(agendamentos, agora: datetime):
    """Prejuízo evitado mês a mês, do mês mais antigo para o mais recente."""
    meses = []
    for indice in range(MESES_GRAFICO - 1, -1, -1):
        inicio = _inicio_do_mes(agora, indice)
        fim = _inicio_do_mes(agora, indice - 1)
        valor = sum(
            agendamento.valor or 0
            for agendamento in agendamentos
            if _e_encaixe(agendamento) and inicio <= agendamento.data_hora < fim
        )
        meses.append({
            'mes': MESES_ABREVIADOS[inicio.month - 1],
            'valor': round(valor, 2),
        })
    return meses


def montar_resumo(dentista_id: int, agora: datetime | None = None) -> dict:
    """Monta o JSON completo do painel para um dentista."""
    agora = agora or datetime.now()

    inicio_resumo = _inicio_do_mes(agora, MESES_RESUMO - 1)
    inicio_grafico = _inicio_do_mes(agora, MESES_GRAFICO - 1)

    # Uma única leitura cobre o gráfico (6 meses) e o resumo (3 meses).
    todos = (
        Agendamento.query
        .filter(
            Agendamento.dentista_id == dentista_id,
            Agendamento.data_hora >= inicio_grafico,
        )
        .all()
    )
    do_resumo = [a for a in todos if a.data_hora >= inicio_resumo]

    encaixes = [a for a in do_resumo if _e_encaixe(a)]
    prejuizo_evitado = sum(a.valor or 0 for a in encaixes)
    horarios_recuperados = len(encaixes)
    pacientes_encaixados = len(
        {a.nome_paciente for a in encaixes if a.nome_paciente}
    )

    # Ocupação e ociosidade olham só para horários que já passaram: um horário
    # vago amanhã ainda pode ser preenchido, e contá-lo como ociosidade agora
    # faria o painel parecer pior do que a clínica está.
    passados = [
        a for a in do_resumo
        if a.status != 'cancelado' and a.data_hora <= agora
    ]
    minutos_totais = sum(a.duracao for a in passados)
    minutos_ocupados = sum(a.duracao for a in passados if not a.vago)

    if minutos_totais:
        taxa_ocupacao = minutos_ocupados / minutos_totais * 100
        ociosidade = 100 - taxa_ocupacao
    else:
        taxa_ocupacao = 0.0
        ociosidade = 0.0

    return {
        'prejuizo_evitado': round(prejuizo_evitado, 2),
        'ociosidade': round(ociosidade, 1),
        'horarios_recuperados': horarios_recuperados,
        'pacientes_encaixados': pacientes_encaixados,
        'resumo_3_meses': {
            'consultas_realizadas': sum(
                1 for a in do_resumo if a.status == 'concluido'
            ),
            'cancelamentos': sum(
                1 for a in do_resumo if a.status == 'cancelado'
            ),
            'horarios_recuperados': horarios_recuperados,
            'taxa_ocupacao': round(taxa_ocupacao, 1),
        },
        'desempenho': _desempenho_por_mes(todos, agora),
    }
