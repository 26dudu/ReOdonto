import re


def chave_telefone(numero):
    digitos = re.sub(r'\D', '', numero or '')
    if digitos.startswith('55') and len(digitos) > 11:
        digitos = digitos[2:]
    if len(digitos) < 10:
        return ''
    return digitos[:2] + digitos[-8:]
