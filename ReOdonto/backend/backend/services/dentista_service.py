from database.db import db
from models.dentista_model import Dentista

def criar_dentista(data):
    dentista = Dentista(nome=data['nome'])
    db.session.add(dentista)
    db.session.commit()
    return dentista

def listar_dentistas():
    return Dentista.query.all()

def buscar_dentista(id):
    return Dentista.query.get_or_404(id)

def atualizar_dentista(id, data):
    dentista = Dentista.query.get_or_404(id)
    dentista.nome = data['nome']
    db.session.commit()
    return dentista

def deletar_dentista(id):
    dentista = Dentista.query.get_or_404(id)
    db.session.delete(dentista)
    db.session.commit()
