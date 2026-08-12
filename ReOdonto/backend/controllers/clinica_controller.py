from flask import Blueprint, request, jsonify
import services.clinica_service as service

clinica_bp = Blueprint('clinica', __name__, url_prefix='/clinicas')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


@clinica_bp.route('/', methods=['POST'])
def criar():
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        clinica = service.criar_clinica(data)
        return jsonify(clinica.to_dict()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@clinica_bp.route('/', methods=['GET'])
def listar():
    """
    Lista clínicas com paginação.
    GET /clinicas/?page=1&per_page=20
    """
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 20, type=int), 100)  # máximo 100
    paginacao = service.listar_clinicas_paginado(page=page, per_page=per_page)
    return jsonify({
        'clinicas': [c.to_dict() for c in paginacao.items],
        'total': paginacao.total,
        'pagina': paginacao.page,
        'paginas': paginacao.pages,
    })


@clinica_bp.route('/<int:id>', methods=['GET'])
def buscar(id):
    return jsonify(service.buscar_clinica(id).to_dict())


@clinica_bp.route('/<int:id>', methods=['PUT'])
def atualizar(id):
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        clinica = service.atualizar_clinica(id, data)
        return jsonify(clinica.to_dict())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@clinica_bp.route('/<int:id>', methods=['DELETE'])
def deletar(id):
    service.deletar_clinica(id)
    return '', 204
