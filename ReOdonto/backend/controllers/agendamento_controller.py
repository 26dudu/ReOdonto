from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
import services.agendamento_service as service

agendamento_bp = Blueprint('agendamento', __name__, url_prefix='/agendamentos')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


def _dentista_id_do_token():
    """
    Extrai dentista_id do JWT.
    O token pode ter sido criado com identity = dentista_id (int)
    ou pode ter o claim extra 'dentista_id'.
    """
    claims = get_jwt()
    if 'dentista_id' in claims:
        return int(claims['dentista_id'])
    return int(get_jwt_identity())


@agendamento_bp.route('/', methods=['POST'])
@jwt_required()
def criar():
    data, erro = _json_ou_erro()
    if erro:
        return erro

    # Usa dentista_id do token (dentista logado só cria para si mesmo)
    data['dentista_id'] = _dentista_id_do_token()

    try:
        agendamento = service.criar_agendamento(data)
        return jsonify(agendamento.to_dict_completo()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@agendamento_bp.route('/', methods=['GET'])
@jwt_required()
def listar():
    """
    GET /agendamentos/
    Retorna todos os agendamentos do dentista logado.
    """
    dentista_id = _dentista_id_do_token()
    agendamentos = service.listar_agendamentos(dentista_id=dentista_id)
    return jsonify([a.to_dict_completo() for a in agendamentos])


@agendamento_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    agendamento = service.buscar_agendamento(id)
    dentista_id = _dentista_id_do_token()
    if agendamento.dentista_id != dentista_id:
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
    dentista_id = _dentista_id_do_token()
    if agendamento.dentista_id != dentista_id:
        return jsonify({'erro': 'Acesso negado'}), 403

    novo_status = data.get('status')
    if not novo_status:
        return jsonify({'erro': 'Campo status é obrigatório'}), 400

    try:
        agendamento = service.atualizar_status(id, novo_status)
        return jsonify(agendamento.to_dict_completo())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@agendamento_bp.route('/<int:id>/paciente-rapido', methods=['PATCH'])
@jwt_required()
def preencher_paciente(id):
    """
    Preenche nome e telefone de um horário vago (walk-in).
    Body: { "nome": "João Silva", "telefone": "31999999999" }
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    agendamento = service.buscar_agendamento(id)
    dentista_id = _dentista_id_do_token()
    if agendamento.dentista_id != dentista_id:
        return jsonify({'erro': 'Acesso negado'}), 403

    nome = data.get('nome', '').strip()
    telefone = data.get('telefone', '').strip()
    if not nome:
        return jsonify({'erro': 'Campo nome é obrigatório'}), 400

    try:
        agendamento = service.preencher_paciente(id, nome, telefone)
        return jsonify(agendamento.to_dict_completo())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@agendamento_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def deletar(id):
    agendamento = service.buscar_agendamento(id)
    dentista_id = _dentista_id_do_token()
    if agendamento.dentista_id != dentista_id:
        return jsonify({'erro': 'Acesso negado'}), 403
    service.deletar_agendamento(id)
    return '', 204
