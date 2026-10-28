"""
Rotas de recuperação de senha, compartilhadas entre os blueprints.

O mesmo par de rotas é registrado sob /dentistas e sob /pacientes. O serviço
aceita os dois tipos de conta, e manter as duas evita quebrar clientes que já
chamavam /pacientes/recuperar-senha quando o fluxo era só de paciente.
"""
from flask import request, jsonify

import services.recuperacao_service as service


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (
            jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}),
            400,
        )
    return data, None


def recuperar_senha():
    """
    Solicita o código de recuperação. Rota pública.
    Body: { "email": "..." }

    Respostas: 200 enviado, 404 email não cadastrado, 429 limite por hora
    atingido, 400 email inválido, 500 erro interno.

    O 404 revela que o email não está cadastrado. É uma troca consciente:
    sem ele, quem digita o email errado fica esperando um código que nunca
    chega. Para um app público valeria responder sempre 200 e uma mensagem
    genérica, evitando enumeração de usuários.
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    email = data.get('email', '').strip()
    if not email or '@' not in email:
        return jsonify({'erro': 'Email inválido'}), 400

    try:
        resultado = service.solicitar_codigo(email)
    except RuntimeError as e:
        return jsonify({'erro': str(e)}), 500
    except Exception:
        return jsonify({'erro': 'Erro ao processar solicitação'}), 500

    if resultado == service.NAO_ENCONTRADO:
        return jsonify({'erro': 'Email não encontrado'}), 404

    if resultado == service.LIMITE_EXCEDIDO:
        return jsonify({
            'erro': 'Você já pediu o código várias vezes. Aguarde uma hora e tente de novo.'
        }), 429

    return jsonify({
        'mensagem': 'Código de verificação enviado. Verifique seu email.'
    }), 200


def redefinir_senha():
    """
    Redefine a senha com o código recebido. Rota pública.
    Body: { "email": "...", "codigo": "123456", "nova_senha": "..." }
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    email = data.get('email', '').strip()
    codigo = data.get('codigo', '').strip()
    nova_senha = data.get('nova_senha', '')

    if not email or not codigo or not nova_senha:
        return jsonify({
            'erro': 'Campos email, codigo e nova_senha são obrigatórios'
        }), 400

    try:
        service.redefinir(email, codigo, nova_senha)
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400

    return jsonify({'mensagem': 'Senha redefinida com sucesso'}), 200


def registrar(blueprint):
    """Adiciona /recuperar-senha e /redefinir-senha ao blueprint informado."""
    blueprint.add_url_rule(
        '/recuperar-senha', 'recuperar_senha', recuperar_senha, methods=['POST']
    )
    blueprint.add_url_rule(
        '/redefinir-senha', 'redefinir_senha', redefinir_senha, methods=['POST']
    )
