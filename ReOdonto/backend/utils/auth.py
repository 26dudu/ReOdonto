"""Helpers de autorização compartilhados pelos controllers."""
from functools import wraps

from flask import g, jsonify
from flask_jwt_extended import jwt_required, get_jwt


def dentista_id_do_token():
    """
    Devolve o dentista_id do JWT, ou None quando o token não é de um dentista.

    Exige o claim 'dentista_id' e tipo == 'dentista'. Não existe fallback para
    o 'sub' do token: o 'sub' de um token de paciente é o id do paciente, e
    aceitá-lo deixava o paciente de id N agir como o dentista de id N — como
    o cadastro e o login de paciente são públicos, qualquer pessoa conseguia
    ler e cancelar a agenda do dentista.
    """
    claims = get_jwt()
    if claims.get('tipo') != 'dentista':
        return None
    try:
        return int(claims['dentista_id'])
    except (KeyError, TypeError, ValueError):
        return None


def dentista_required(fn):
    """
    Exige um JWT de dentista e deixa o id em `g.dentista_id`.

    Substitui o par `@jwt_required()` + leitura manual do claim, para que
    nenhuma rota de dentista esqueça a checagem de tipo.
    """

    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        dentista_id = dentista_id_do_token()
        if dentista_id is None:
            return jsonify({'erro': 'Esta área é exclusiva de dentistas'}), 403
        g.dentista_id = dentista_id
        return fn(*args, **kwargs)

    return wrapper
