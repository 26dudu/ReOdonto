import re

import requests

BASE = "https://brasilapi.com.br/api/cep/v2"


def _limpar_cep(cep):
    return re.sub(r"\D", "", str(cep))


def buscar_cep(cep):
    cep_limpo = _limpar_cep(cep)
    if len(cep_limpo) != 8:
        raise ValueError("CEP deve ter 8 dígitos")

    url = f"{BASE}/{cep_limpo}"
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    data = r.json()

    return {
        "cep": data.get("cep", cep_limpo),
        "logradouro": data.get("street", ""),
        "bairro": data.get("neighborhood", ""),
        "cidade": data.get("city", ""),
        "estado": data.get("state", ""),
        "fonte": "Brasil API",
    }