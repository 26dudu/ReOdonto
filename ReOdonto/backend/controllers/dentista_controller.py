from flask import Blueprint, request, jsonify, g
from flask_jwt_extended import create_access_token

import services.dentista_service as service
from controllers import recuperacao_rotas
from utils.auth import dentista_required

dentista_bp = Blueprint('dentista', __name__, url_prefix='/dentistas')


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (
            jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}),
            400,
        )
    return data, None


def _negar_se_nao_for_o_dono(id):
    """
    Devolve uma resposta 403 quando o dentista logado não é o dono do id.

    Sem esta checagem qualquer dentista autenticado podia editar ou apagar
    a conta de outro: bastava trocar o id na URL.
    """
    if id != g.dentista_id:
        return jsonify({'erro': 'Acesso negado'}), 403
    return None


# --- Rotas públicas ---

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


@dentista_bp.route('/', methods=['POST'])
def criar():
    """Cadastro — rota pública."""
    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        dentista = service.criar_dentista(data)
        return jsonify(dentista.to_dict()), 201
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


# /dentistas/recuperar-senha e /dentistas/redefinir-senha
recuperacao_rotas.registrar(dentista_bp)


# --- Rotas autenticadas ---

@dentista_bp.route('/', methods=['GET'])
@dentista_required
def listar():
    """Lista dentistas, opcionalmente filtrados por clínica.

    GET /dentistas/              → todos os dentistas
    GET /dentistas/?clinica_id=X → dentistas que atendem na clínica X
    """
    clinica_id = request.args.get('clinica_id', type=int)
    dentistas = service.listar_dentistas(clinica_id=clinica_id)
    return jsonify([d.to_dict() for d in dentistas])


@dentista_bp.route('/<int:id>', methods=['GET'])
@dentista_required
def buscar(id):
    """O dentista só vê o próprio perfil — o to_dict expõe email e CPF/CNPJ."""
    negado = _negar_se_nao_for_o_dono(id)
    if negado:
        return negado
    return jsonify(service.buscar_dentista(id).to_dict())


@dentista_bp.route('/<int:id>', methods=['PUT'])
@dentista_required
def atualizar(id):
    """O dentista só edita o próprio perfil."""
    negado = _negar_se_nao_for_o_dono(id)
    if negado:
        return negado

    data, erro = _json_ou_erro()
    if erro:
        return erro
    try:
        dentista = service.atualizar_dentista(id, data)
        return jsonify(dentista.to_dict())
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@dentista_bp.route('/<int:id>', methods=['DELETE'])
@dentista_required
def deletar(id):
    """O dentista só apaga a própria conta."""
    negado = _negar_se_nao_for_o_dono(id)
    if negado:
        return negado
    service.deletar_dentista(id)
    return '', 204
