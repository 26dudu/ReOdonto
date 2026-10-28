from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    jwt_required,
    get_jwt_identity,
    create_access_token,
    get_jwt,
)
import services.paciente_service as service
from controllers import recuperacao_rotas

paciente_bp = Blueprint('paciente', __name__, url_prefix='/pacientes')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}), 400)
    return data, None


def _negar_se_nao_for_o_dono(id):
    """
    Devolve 403 quando o token não é de um paciente ou não é o dono do id.

    A checagem de tipo é necessária porque o 'sub' de um token de dentista é
    o id do dentista: sem ela, o dentista de id N acessava o paciente de id N.
    """
    claims = get_jwt()
    if claims.get('tipo') != 'paciente':
        return jsonify({'erro': 'Acesso negado'}), 403
    try:
        if int(get_jwt_identity()) != id:
            return jsonify({'erro': 'Acesso negado'}), 403
    except (TypeError, ValueError):
        return jsonify({'erro': 'Acesso negado'}), 403
    return None


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
    """Login — rota pública. Retorna JWT em caso de sucesso.
    
    O token JWT é assinado com JWT_SECRET_KEY (HS256 por padrão no flask-jwt-extended)
    e carrega como identidade o id do paciente. Dados adicionais (nome, email)
    são embutidos como additional_claims para que o Flutter possa lê-los
    sem precisar de uma chamada extra ao /pacientes/<id> logo após o login.
    """
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

        paciente_dict = paciente.to_dict()

        # Emite token JWT assinado:
        # - identity: id do paciente (string, como exige flask-jwt-extended)
        # - additional_claims: dados públicos do paciente embutidos no payload
        #   (não inclui senha nem dados criptografados sensíveis)
        additional_claims = {
            'nome':  paciente_dict.get('nome'),
            'email': paciente_dict.get('email'),
            'tipo':  'paciente',
        }
        token = create_access_token(
            identity=str(paciente.id),
            additional_claims=additional_claims,
        )
        return jsonify({
            'token': token,
            'paciente': paciente_dict,
        }), 200
    except ValueError as e:
        return jsonify({'erro': str(e)}), 401


@paciente_bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def buscar(id):
    """Paciente só pode ver o próprio perfil."""
    negado = _negar_se_nao_for_o_dono(id)
    if negado:
        return negado
    return jsonify(service.buscar_paciente(id).to_dict())


@paciente_bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def atualizar(id):
    """Paciente só pode editar o próprio perfil."""
    negado = _negar_se_nao_for_o_dono(id)
    if negado:
        return negado

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
    negado = _negar_se_nao_for_o_dono(id)
    if negado:
        return negado
    service.deletar_paciente(id)
    return '', 204


# /pacientes/recuperar-senha e /pacientes/redefinir-senha — os handlers são
# os mesmos usados em /dentistas e atendem os dois tipos de conta.
recuperacao_rotas.registrar(paciente_bp)
