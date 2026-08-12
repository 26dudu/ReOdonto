from flask import Blueprint, request, jsonify
import services.dentista_service as service

dentista_bp = Blueprint('dentista', __name__, url_prefix='/dentistas')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


@dentista_bp.route('/', methods=['POST'])
def criar():
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        dentista = service.criar_dentista(data)
        return jsonify(dentista.to_dict()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@dentista_bp.route('/', methods=['GET'])
def listar():
    return jsonify([d.to_dict() for d in service.listar_dentistas()])


@dentista_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_dentista(id).to_dict())


@dentista_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        dentista = service.atualizar_dentista(id, data)
        return jsonify(dentista.to_dict())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@dentista_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_dentista(id)
    return '', 204
