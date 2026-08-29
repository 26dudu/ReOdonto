"""
seed.py — Popula o banco com dados iniciais (clínica + tipos de consulta).

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
from models.consulta_model import Consulta


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

    # ── Consultas (tipos de procedimento) ────────────────────
    tipos = [
        ('Consulta de Rotina',   'Avaliação geral da saúde bucal',       150.0, 30),
        ('Limpeza Dental',       'Remoção de tártaro e polimento',        200.0, 45),
        ('Extração Simples',     'Extração de dente sem complicações',    300.0, 60),
        ('Canal',                'Tratamento endodôntico',                800.0, 90),
        ('Clareamento',          'Clareamento dental a laser',            600.0, 60),
        ('Aparelho Ortodôntico', 'Instalação e manutenção de aparelho',   250.0, 30),
        ('Restauração',          'Restauração com resina composta',       350.0, 45),
    ]
    consulta_ids = []
    for nome, desc, valor, dur in tipos:
        c = Consulta.query.filter_by(nome=nome).first()
        if not c:
            c = Consulta(nome=nome, descricao=desc, valor=valor, duracao_minutos=dur)
            db.session.add(c)
            db.session.flush()
            print(f' Consulta criada: {c.nome} (id={c.id})')
        else:
            print(f'  Consulta já existe: {c.nome} (id={c.id})')
        consulta_ids.append(c.id)

    db.session.commit()

    print('\n' + '='*50)
    print(' Seed concluído com sucesso!')
    print('='*50)
    print(f'\n Clínica → id={clinica.id} ({clinica.nome})')
    print(f'   Consultas → ids {consulta_ids}')
    print('\n  Próximos passos:')
    print('  1. Inicie o backend: python app.py')
    print('  2. No app Flutter, faça cadastro para criar sua conta de dentista')
