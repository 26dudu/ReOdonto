from flask import Blueprint, request, jsonify
import services.agendamento_service as service

agendamento_bp = Blueprint('agendamento', __name__, url_prefix='/agendamentos')

@agendamento_bp.route('/', methods=['POST'])
def criar():
    return jsonify(service.criar_agendamento(request.json).to_dict()), 201

@agendamento_bp.route('/', methods=['GET'])
def listar():
    return jsonify([a.to_dict() for a in service.listar_agendamentos()])

@agendamento_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_agendamento(id).to_dict())

@agendamento_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    return jsonify(service.atualizar_agendamento(id, request.json).to_dict())

@agendamento_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_agendamento(id)
    return '', 204
