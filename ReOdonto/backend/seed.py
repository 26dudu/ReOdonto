"""
seed.py — Popula o banco com dados iniciais (clínica e dentista de teste).

Execute UMA vez depois de inicializar o banco:
    python seed.py

Para limpar dentistas/pacientes/agendamentos existentes:
    python limpar_banco.py
"""

import os
import sys

# Garante imports relativos corretos
sys.path.insert(0, os.path.dirname(__file__))

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from app import app, db
from models.clinica_model import Clinica
from repositories import dentista_repository
from services import dentista_service

DENTISTA_TESTE = {
    'nome': 'Dentista Teste',
    'email': 'teste@reodonto.com',
    'senha': 'Teste12345',
    'telefone': '31999990000',
    'cro': 'MG-12345',
    'cpf_cnpj': '52998224725',
}


with app.app_context():
    db.create_all()

    # ── Clínica ──────────────────────────────────────────────
    clinica = Clinica.query.first()
    if not clinica:
        clinica = Clinica(
            nome='Clínica ReOdonto',
            telefone='(31) 99999-0001',
            email='contato@reodonto.com',
            cep='30130-110',
            rua='Rua dos Dentistas',
            bairro='Centro',
            numero='100',
            cidade='Belo Horizonte',
            estado='MG',
        )
        db.session.add(clinica)
        db.session.flush()
        print(f' Clínica criada: {clinica.nome} (id={clinica.id})')
    else:
        print(f'  Clínica já existe: {clinica.nome} (id={clinica.id})')

    db.session.commit()

    dentista = dentista_repository.buscar_por_email(DENTISTA_TESTE['email'])
    if not dentista:
        dentista = dentista_service.criar_dentista(DENTISTA_TESTE)
        print(f' Dentista de teste criado: {dentista.email} (id={dentista.id})')
    else:
        print(f'  Dentista de teste já existe: {dentista.email} (id={dentista.id})')

    print('\n' + '='*50)
    print(' Seed concluído com sucesso!')
    print('='*50)
    print(f'\n Clínica → id={clinica.id} ({clinica.nome})')
    print(f" Dentista de teste → {DENTISTA_TESTE['email']} / {DENTISTA_TESTE['senha']}")
    print('\n  Próximos passos:')
    print('  1. Inicie o backend: python app.py')
    print('  2. No app Flutter, entre com o dentista de teste ou cadastre sua própria conta')
