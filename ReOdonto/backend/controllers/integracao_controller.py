import hmac
import os

from flask import Blueprint, request, jsonify

import services.whatsapp_service as whatsapp_service

integracao_bp = Blueprint('integracao', __name__, url_prefix='/integracoes')


def _chave_valida():
    esperada = os.environ.get('INTEGRACAO_API_KEY', '')
    if not esperada:
        return None
    enviada = request.headers.get('X-API-Key', '')
    return hmac.compare_digest(enviada, esperada)


def _executar(acao):
    valida = _chave_valida()
    if valida is None:
        return jsonify({'erro': 'Integração desativada: defina INTEGRACAO_API_KEY'}), 503
    if not valida:
        return jsonify({'erro': 'Chave de API inválida'}), 401

    data = request.get_json(silent=True)
    if data is None:
        return jsonify({'erro': 'Body deve ser JSON válido'}), 400

    try:
        return jsonify(acao(data)), 200
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400


@integracao_bp.route('/whatsapp/agendar', methods=['POST'])
def agendar_por_whatsapp():
    return _executar(whatsapp_service.agendar)


@integracao_bp.route('/whatsapp/cancelar', methods=['POST'])
def cancelar_por_whatsapp():
    return _executar(whatsapp_service.cancelar)
