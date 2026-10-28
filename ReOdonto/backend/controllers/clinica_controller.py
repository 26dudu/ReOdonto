from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
import services.clinica_service as service
from utils.auth import dentista_required

clinica_bp = Blueprint('clinica', __name__, url_prefix='/clinicas')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


# --- Rotas de leitura — requerem login ---

@clinica_bp.route('/', methods=['GET'])
@jwt_required()
def listar():
    """
    Lista clínicas com paginação. Requer paciente logado.
    GET /clinicas/?page=1&per_page=20
    """
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 20, type=int), 100)
    paginacao = service.listar_clinicas_paginado(page=page, per_page=per_page)
    return jsonify({
        'clinicas': [c.to_dict() for c in paginacao.items],
        'total': paginacao.total,
        'pagina': paginacao.page,
        'paginas': paginacao.pages,
    })


@clinica_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    return jsonify(service.buscar_clinica(id).to_dict())


# --- Rotas de escrita — restritas a dentistas ---
# Clínica é cadastro da operação, não do paciente: antes qualquer conta
# autenticada (inclusive um paciente recém-cadastrado) podia criar, editar
# e apagar clínicas.

@clinica_bp.route('/', methods=['POST'])
@dentista_required
def criar():
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        clinica = service.criar_clinica(data)
        return jsonify(clinica.to_dict()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@clinica_bp.route('/<int:id>', methods=['PUT'])
@dentista_required
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
@dentista_required
def deletar(id):
    service.deletar_clinica(id)
    return '', 204
