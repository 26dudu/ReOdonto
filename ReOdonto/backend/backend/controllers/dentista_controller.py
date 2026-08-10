from flask import Blueprint, request, jsonify
import services.dentista_service as service

dentista_bp = Blueprint('dentista', __name__, url_prefix='/dentistas')

@dentista_bp.route('/', methods=['POST'])
def criar():
    return jsonify(service.criar_dentista(request.json).to_dict()), 201

@dentista_bp.route('/', methods=['GET'])
def listar():
    return jsonify([d.to_dict() for d in service.listar_dentistas()])

@dentista_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_dentista(id).to_dict())

@dentista_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    return jsonify(service.atualizar_dentista(id, request.json).to_dict())

@dentista_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_dentista(id)
    return '', 204
