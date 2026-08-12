from flask import Blueprint, jsonify
import services.brasilapi_cep as cep_service
import requests

cep_bp = Blueprint('cep', __name__, url_prefix='/cep')


@cep_bp.route('/<string:cep>', methods=['GET'])
def buscar(cep):
    """
    Busca endereço pelo CEP usando a BrasilAPI.
    GET /cep/30150380  ou  GET /cep/30150-380
    """
    try:
        dados = cep_service.buscar_cep(cep)
        return jsonify(dados), 200
    except ValueError as e:
        return jsonify({'erro': str(e)}), 400
    except requests.exceptions.HTTPError as e:
        if e.response is not None and e.response.status_code == 404:
            return jsonify({'erro': 'CEP não encontrado'}), 404
        return jsonify({'erro': 'Erro ao consultar a BrasilAPI'}), 502
    except requests.exceptions.RequestException:
        return jsonify({'erro': 'Sem conexão com a BrasilAPI'}), 503
