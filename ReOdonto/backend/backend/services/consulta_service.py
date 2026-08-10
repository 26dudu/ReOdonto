from database.db import db
from models.consulta_model import Consulta

def criar_consulta(data):
    consulta = Consulta(nome=data['nome'], descricao=data['descricao'], valor=data['valor'])
    db.session.add(consulta)
    db.session.commit()
    return consulta

def listar_consultas():
    return Consulta.query.all()

def buscar_consulta(id):
    return Consulta.query.get_or_404(id)

def atualizar_consulta(id, data):
    consulta = Consulta.query.get_or_404(id)
    consulta.nome = data['nome']
    consulta.descricao = data['descricao']
    consulta.valor = data['valor']
    db.session.commit()
    return consulta

def deletar_consulta(id):
    consulta = Consulta.query.get_or_404(id)
    db.session.delete(consulta)
    db.session.commit()
