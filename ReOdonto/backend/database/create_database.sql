-- create_database.sql
-- Schema de referência, GERADO a partir dos models SQLAlchemy.
-- O banco é criado automaticamente por db.create_all() ao iniciar app.py;
-- este arquivo serve só de documentação. Para regenerar depois de mudar
-- um model, compile CreateTable(tabela) de cada tabela em db.metadata.
--
-- Agendamento sem nome_paciente = horário vago. duracao_minutos é a base
-- da checagem de conflito; valor e encaixe alimentam o painel.
-- status possíveis: agendado, concluido, cancelado.

CREATE TABLE IF NOT EXISTS clinica (
	id INTEGER NOT NULL, 
	nome VARCHAR(100) NOT NULL, 
	telefone VARCHAR(20), 
	email VARCHAR(150), 
	cep VARCHAR(9), 
	rua VARCHAR(150), 
	bairro VARCHAR(100), 
	numero VARCHAR(10), 
	cidade VARCHAR(100), 
	estado VARCHAR(2), 
	PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS consulta (
	id INTEGER NOT NULL, 
	nome VARCHAR(100) NOT NULL, 
	descricao TEXT NOT NULL, 
	valor FLOAT NOT NULL, 
	duracao_minutos INTEGER, 
	PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS dentista (
	id INTEGER NOT NULL, 
	nome VARCHAR(100) NOT NULL, 
	email VARCHAR(150) NOT NULL, 
	senha VARCHAR(255) NOT NULL, 
	telefone VARCHAR(20), 
	cro VARCHAR(20), 
	cpf_cnpj VARCHAR(14), 
	PRIMARY KEY (id), 
	UNIQUE (email), 
	UNIQUE (cpf_cnpj)
);

CREATE TABLE IF NOT EXISTS paciente (
	id INTEGER NOT NULL, 
	nome TEXT NOT NULL, 
	email TEXT NOT NULL, 
	email_hash VARCHAR(64) NOT NULL, 
	senha VARCHAR(255) NOT NULL, 
	telefone TEXT, 
	cpf TEXT, 
	cpf_hash VARCHAR(64), 
	cep TEXT, 
	rua TEXT, 
	bairro TEXT, 
	numero TEXT, 
	PRIMARY KEY (id), 
	UNIQUE (email_hash), 
	UNIQUE (cpf_hash)
);

CREATE TABLE IF NOT EXISTS recuperacao_senha (
	id INTEGER NOT NULL, 
	email_hash VARCHAR(64) NOT NULL, 
	codigo_hash VARCHAR(64) NOT NULL, 
	expira_em DATETIME NOT NULL, 
	usado BOOLEAN NOT NULL, 
	criado_em DATETIME NOT NULL, 
	PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS ix_recuperacao_senha_email_hash ON recuperacao_senha (email_hash);

CREATE TABLE IF NOT EXISTS agendamento (
	id INTEGER NOT NULL, 
	dentista_id INTEGER NOT NULL, 
	clinica_id INTEGER, 
	consulta_customizada VARCHAR(200), 
	nome_paciente VARCHAR(100), 
	telefone_paciente VARCHAR(20), 
	data_hora DATETIME NOT NULL, 
	duracao_minutos INTEGER NOT NULL, 
	valor FLOAT, 
	encaixe BOOLEAN NOT NULL, 
	status VARCHAR(20) NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(dentista_id) REFERENCES dentista (id), 
	FOREIGN KEY(clinica_id) REFERENCES clinica (id)
);
