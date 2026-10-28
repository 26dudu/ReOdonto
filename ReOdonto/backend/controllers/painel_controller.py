from flask import Blueprint, jsonify, g

import services.painel_service as service
from utils.auth import dentista_required

painel_bp = Blueprint('painel', __name__, url_prefix='/painel')


@painel_bp.route('/resumo', methods=['GET'])
@dentista_required
def resumo():
    """
    GET /painel/resumo — indicadores do Painel Administrativo.

    Devolve o JSON que ResumoPainel.fromJson consome no app: os cartões do
    topo, o bloco "Resumo dos últimos 3 meses" e as barras do gráfico.
    """
    return jsonify(service.montar_resumo(g.dentista_id))
