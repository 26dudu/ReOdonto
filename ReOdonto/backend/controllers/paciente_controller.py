from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token
import services.paciente_service as service

paciente_bp = Blueprint('paciente', __name__, url_prefix='/pacientes')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


@paciente_bp.route('/', methods=['POST'])
def criar():
    """Cadastro — rota pública."""
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        paciente = service.criar_paciente(data)
        return jsonify(paciente.to_dict()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@paciente_bp.route('/login', methods=['POST'])
def login():
    """Login — rota pública. Retorna JWT em caso de sucesso."""
    data, erro = _json_ou_erro()
    if erro:
        return erro

    email = data.get('email')
    senha = data.get('senha')

    if not email or not senha:
        return jsonify({'erro': 'Email e senha são obrigatórios'}), 400

    try:
        paciente = service.buscar_paciente_por_email(email)
        if not service.verificar_senha(paciente, senha):
            return jsonify({'erro': 'Email ou senha inválidos'}), 401

        # Emite token JWT com o id do paciente como identidade
        token = create_access_token(identity=str(paciente.id))
        return jsonify({
            'token': token,
            'paciente': paciente.to_dict(),
        }), 200
    except ValueError as e:
        return jsonify({'erro': str(e)}), 401


@paciente_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    """Paciente só pode ver o próprio perfil."""
    paciente_logado = int(get_jwt_identity())
    if id != paciente_logado:
        return jsonify({'erro': 'Acesso negado'}), 403
    return jsonify(service.buscar_paciente(id).to_dict())


@paciente_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def atualizar(id):
    """Paciente só pode editar o próprio perfil."""
    paciente_logado = int(get_jwt_identity())
    if id != paciente_logado:
        return jsonify({'erro': 'Acesso negado'}), 403

    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        paciente = service.atualizar_paciente(id, data)
        return jsonify(paciente.to_dict())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@paciente_bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def deletar(id):
    """Paciente só pode deletar a própria conta."""
    paciente_logado = int(get_jwt_identity())
    if id != paciente_logado:
        return jsonify({'erro': 'Acesso negado'}), 403
    service.deletar_paciente(id)
    return '', 204
