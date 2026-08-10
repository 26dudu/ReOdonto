from flask import Blueprint, request, jsonify
import services.paciente_service as service

paciente_bp = Blueprint('paciente', __name__, url_prefix='/pacientes')

@paciente_bp.route('/', methods=['POST'])
def criar():
    return jsonify(service.criar_paciente(request.json).to_dict()), 201

@paciente_bp.route('/', methods=['GET'])
def listar():
    return jsonify([p.to_dict() for p in service.listar_pacientes()])

@paciente_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_paciente(id).to_dict())

@paciente_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    return jsonify(service.atualizar_paciente(id, request.json).to_dict())

@paciente_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_paciente(id)
    return '', 204
