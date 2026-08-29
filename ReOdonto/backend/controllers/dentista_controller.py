from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, create_access_token
import services.dentista_service as service

dentista_bp = Blueprint('dentista', __name__, url_prefix='/dentistas')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


@dentista_bp.route('/login', methods=['POST'])
def login():
    """POST /dentistas/login  — { "email": "...", "senha": "..." }"""
    data, erro = _json_ou_erro()
    if erro:
        return erro

    email = data.get('email', '').strip()
    senha = data.get('senha', '')
    if not email or not senha:
        return jsonify({'erro': 'Email e senha são obrigatórios'}), 400

    try:
        dentista = service.login_dentista(email, senha)
    except ValueError as e:
        return jsonify({'erro': str(e)}), 401

    token = create_access_token(
        identity=str(dentista.id),
        additional_claims={
            'nome': dentista.nome,
            'email': dentista.email,
            'tipo': 'dentista',
            'dentista_id': dentista.id,
        },
    )
    return jsonify({'token': token, 'dentista': dentista.to_dict()}), 200

@dentista_bp.route('/', methods=['GET'])
@jwt_required()
def listar():
    """Lista dentistas, opcionalmente filtrados por clínica.
    
    GET /dentistas/            → todos os dentistas
    GET /dentistas/?clinica_id=X → dentistas que atendem na clínica X
    """
    clinica_id = request.args.get('clinica_id', type=int)
    dentistas = service.listar_dentistas(clinica_id=clinica_id)
    return jsonify([d.to_dict() for d in dentistas])


@dentista_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    return jsonify(service.buscar_dentista(id).to_dict())


# --- Rotas de escrita — requerem login ---
# Em produção estas rotas devem ser restritas a um perfil admin.
# Por ora, jwt_required já impede acesso sem token.

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


@dentista_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
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
@jwt_required()
def deletar(id):
    service.deletar_dentista(id)
    return '', 204
