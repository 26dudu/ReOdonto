from flask import Blueprint, request, jsonify
import services.clinica_service as service

clinica_bp = Blueprint('clinica', __name__, url_prefix='/clinicas')

@clinica_bp.route('/', methods=['POST'])
def criar():
    return jsonify(service.criar_clinica(request.json).to_dict()), 201

@clinica_bp.route('/', methods=['GET'])
def listar():
    return jsonify([c.to_dict() for c in service.listar_clinicas()])

@clinica_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_clinica(id).to_dict())

@clinica_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    return jsonify(service.atualizar_clinica(id, request.json).to_dict())

@clinica_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_clinica(id)
    return '', 204
