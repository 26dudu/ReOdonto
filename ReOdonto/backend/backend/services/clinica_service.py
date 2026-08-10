from database.db import db
from models.clinica_model import Clinica

def criar_clinica(data):
    clinica = Clinica(nome=data['nome'])
    db.session.add(clinica)
    db.session.commit()
    return clinica

def listar_clinicas():
    return Clinica.query.all()

def buscar_clinica(id):
    return Clinica.query.get_or_404(id)

def atualizar_clinica(id, data):
    clinica = Clinica.query.get_or_404(id)
    clinica.nome = data['nome']
    db.session.commit()
    return clinica

def deletar_clinica(id):
    clinica = Clinica.query.get_or_404(id)
    db.session.delete(clinica)
    db.session.commit()
