from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import services.agendamento_service as service

agendamento_bp = Blueprint('agendamento', __name__, url_prefix='/agendamentos')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


@agendamento_bp.route('/', methods=['POST'])
@jwt_required()
def criar():
    data, erro = _json_ou_erro()
    if erro:
        return erro

    # Garante que o paciente só cria agendamento para si mesmo
    paciente_logado = int(get_jwt_identity())
    data['paciente_id'] = paciente_logado

    try:
        agendamento = service.criar_agendamento(data)
        return jsonify(agendamento.to_dict_completo()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@agendamento_bp.route('/', methods=['GET'])
@jwt_required()
def listar():
    """
    GET /agendamentos/?paciente_id=3
    GET /agendamentos/?dentista_id=2
    O paciente logado só pode ver seus próprios agendamentos.
    """
    paciente_logado = int(get_jwt_identity())
    paciente_id = request.args.get('paciente_id', type=int)
    dentista_id = request.args.get('dentista_id', type=int)

    # Paciente não pode ver agendamentos de outros
    if paciente_id and paciente_id != paciente_logado:
        return jsonify({'erro': 'Acesso negado'}), 403

    if not paciente_id and not dentista_id:
        paciente_id = paciente_logado  # padrão: listar os próprios

    agendamentos = service.listar_agendamentos(
        paciente_id=paciente_id,
        dentista_id=dentista_id,
    )
    return jsonify([a.to_dict_completo() for a in agendamentos])


@agendamento_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    agendamento = service.buscar_agendamento(id)
    paciente_logado = int(get_jwt_identity())
    if agendamento.paciente_id != paciente_logado:
        return jsonify({'erro': 'Acesso negado'}), 403
    return jsonify(agendamento.to_dict_completo())


@agendamento_bp.route('/<int:id>/status', methods=['PATCH'])
@jwt_required()
def atualizar_status(id):
    """Body esperado: { "status": "cancelado" }"""
    data, erro = _json_ou_erro()
    if erro:
        return erro

    agendamento = service.buscar_agendamento(id)
    paciente_logado = int(get_jwt_identity())
    if agendamento.paciente_id != paciente_logado:
        return jsonify({'erro': 'Acesso negado'}), 403

    novo_status = data.get('status')
    if not novo_status:
        return jsonify({'erro': 'Campo status é obrigatório'}), 400

    try:
        agendamento = service.atualizar_status(id, novo_status)
        return jsonify(agendamento.to_dict_completo())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@agendamento_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def deletar(id):
    agendamento = service.buscar_agendamento(id)
    paciente_logado = int(get_jwt_identity())
    if agendamento.paciente_id != paciente_logado:
        return jsonify({'erro': 'Acesso negado'}), 403
    service.deletar_agendamento(id)
    return '', 204
