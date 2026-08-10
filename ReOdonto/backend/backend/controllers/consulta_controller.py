from flask import Blueprint, request, jsonify
import services.consulta_service as service

consulta_bp = Blueprint('consulta', __name__, url_prefix='/consultas')

@consulta_bp.route('/', methods=['POST'])
def criar():
    return jsonify(service.criar_consulta(request.json).to_dict()), 201

@consulta_bp.route('/', methods=['GET'])
def listar():
    return jsonify([c.to_dict() for c in service.listar_consultas()])

@consulta_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_consulta(id).to_dict())

@consulta_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    return jsonify(service.atualizar_consulta(id, request.json).to_dict())

@consulta_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_consulta(id)
    return '', 204
