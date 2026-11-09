"""
Rotas da segunda etapa do cadastro do dentista, registradas sob /dentistas.

A primeira etapa é POST /dentistas/ (valida e envia o código). Estas rotas
são públicas porque a conta só passa a existir depois da confirmação.
"""
from flask import jsonify, request

import services.dentista_service as dentista_service
import services.verificacao_email_service as verificacao_service


def _json_ou_erro():
    data = request.get_json(silent=True)
    if data is None:
        return None, (
            jsonify({'erro': 'Body deve ser JSON válido com Content-Type: application/json'}),
            400,
        )
    return data, None


def verificar_email():
    """
    Confirma o código recebido e cria a conta.
    Body: { "email": "...", "codigo": "123456" }
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    email = (data.get('email') or '').strip()
    codigo = (data.get('codigo') or '').strip()
    if not email or not codigo:
        return jsonify({'erro': 'Campos email e codigo são obrigatórios'}), 400

    try:
        dentista = dentista_service.confirmar_cadastro(email, codigo)
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400

    return jsonify({
        'mensagem': 'Email verificado e conta criada com sucesso',
        'dentista': dentista.to_dict(),
    }), 201


def reenviar_verificacao():
    """
    Envia um código novo para um cadastro pendente.
    Body: { "email": "..." }

    Responde 200 mesmo quando não há cadastro pendente, para não revelar quais
    emails têm cadastro. O limite por hora é o único caso com erro (429).
    """
    data, erro = _json_ou_erro()
    if erro:
        return erro

    email = (data.get('email') or '').strip()
    if not email or '@' not in email:
        return jsonify({'erro': 'Email inválido'}), 400

    if verificacao_service.reenviar(email) == verificacao_service.LIMITE_EXCEDIDO:
        return jsonify({
            'erro': 'Você já pediu o código várias vezes. Aguarde uma hora e tente de novo.'
        }), 429

    return jsonify({
        'mensagem': 'Se houver um cadastro pendente para este email, enviamos um novo código.'
    }), 200


def registrar(blueprint):
    """Adiciona /verificar-email e /reenviar-verificacao ao blueprint informado."""
    blueprint.add_url_rule(
        '/verificar-email', 'verificar_email', verificar_email, methods=['POST']
    )
    blueprint.add_url_rule(
        '/reenviar-verificacao', 'reenviar_verificacao', reenviar_verificacao,
        methods=['POST'],
    )
