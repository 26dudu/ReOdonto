from flask import Blueprint, request, jsonify
import services.consulta_service as service

consulta_bp = Blueprint('consulta', __name__, url_prefix='/consultas')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


@consulta_bp.route('/', methods=['POST'])
def criar():
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        consulta = service.criar_consulta(data)
        return jsonify(consulta.to_dict()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@consulta_bp.route('/', methods=['GET'])
def listar():
    return jsonify([c.to_dict() for c in service.listar_consultas()])


@consulta_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_consulta(id).to_dict())


@consulta_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        consulta = service.atualizar_consulta(id, data)
        return jsonify(consulta.to_dict())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@consulta_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_consulta(id)
    return '', 204
