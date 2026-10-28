from flask import Blueprint, request, jsonify, g

import services.agendamento_service as service
from utils.auth import dentista_required

agendamento_bp = Blueprint('agendamento', __name__, url_prefix='/agendamentos')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (
            jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}),
            400,
        )
    return data, None


def _negar_se_nao_for_o_dono(agendamento):
    if agendamento.dentista_id != g.dentista_id:
        return jsonify({'erro': 'Acesso negado'}), 403
    return None


@agendamento_bp.route('/', methods=['POST'])
@dentista_required
def criar():
    """
    Cria um agendamento ou um horário vago.

    Sem `nome_paciente` o registro nasce como horário vago, pronto para
    receber um encaixe depois.
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    # O dentista do token é sempre o dono — o id que vier no corpo é ignorado.
    data['dentista_id'] = g.dentista_id

    try:
        agendamento = service.criar_agendamento(data)
        return jsonify(agendamento.to_dict_completo()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@agendamento_bp.route('/', methods=['GET'])
@dentista_required
def listar():
    """GET /agendamentos/ — agenda do dentista logado, com os horários vagos."""
    agendamentos = service.listar_agendamentos(dentista_id=g.dentista_id)
    return jsonify([a.to_dict_completo() for a in agendamentos])


@agendamento_bp.route('/<int:id>', methods=['GET'])
@dentista_required
def buscar(id):
    agendamento = service.buscar_agendamento(id)
    negado = _negar_se_nao_for_o_dono(agendamento)
    if negado:
        return negado
    return jsonify(agendamento.to_dict_completo())


@agendamento_bp.route('/<int:id>/status', methods=['PATCH'])
@dentista_required
def atualizar_status(id):
    """
    Body esperado: { "status": "cancelado" | "concluido" | "agendado" }

    Ao cancelar um horário que tinha paciente, a resposta traz em
    `horario_liberado` o horário vago que foi aberto no mesmo lugar.
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    agendamento = service.buscar_agendamento(id)
    negado = _negar_se_nao_for_o_dono(agendamento)
    if negado:
        return negado

    novo_status = data.get('status')
    if not novo_status:
        return jsonify({'erro': 'Campo status é obrigatório'}), 400

    try:
        agendamento, horario_vago = service.atualizar_status(id, novo_status)
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400

    resposta = agendamento.to_dict_completo()
    resposta['horario_liberado'] = (
        horario_vago.to_dict_completo() if horario_vago else None
    )
    return jsonify(resposta)


@agendamento_bp.route('/<int:id>/paciente-rapido', methods=['PATCH'])
@dentista_required
def preencher_paciente(id):
    """
    Encaixa um paciente em um horário vago (walk-in).
    Body: { "nome": "João Silva", "telefone": "31999999999" }
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    agendamento = service.buscar_agendamento(id)
    negado = _negar_se_nao_for_o_dono(agendamento)
    if negado:
        return negado

    nome = (data.get('nome') or '').strip()
    telefone = (data.get('telefone') or '').strip()
    consulta = (data.get('consulta_customizada') or '').strip() or None
    if not nome:
        return jsonify({'erro': 'Campo nome é obrigatório'}), 400

    try:
        agendamento = service.preencher_paciente(id, nome, telefone, consulta)
        return jsonify(agendamento.to_dict_completo())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@agendamento_bp.route('/<int:id>', methods=['DELETE'])
@dentista_required
def deletar(id):
    agendamento = service.buscar_agendamento(id)
    negado = _negar_se_nao_for_o_dono(agendamento)
    if negado:
        return negado
    service.deletar_agendamento(id)
    return '', 204
