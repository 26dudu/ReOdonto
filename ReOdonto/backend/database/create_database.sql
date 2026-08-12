-- create_database.sql

CREATE TABLE paciente (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE dentista (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE clinica (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE consulta (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT NOT NULL,
    valor FLOAT NOT NULL
);

CREATE TABLE consulta_pre_requisitos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    consulta_id INTEGER NOT NULL,
    pre_requisito VARCHAR(100) NOT NULL,
    FOREIGN KEY (consulta_id) REFERENCES consulta(id)
);

CREATE TABLE dentista_agenda (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dentista_id INTEGER NOT NULL,
    data DATETIME NOT NULL,
    FOREIGN KEY (dentista_id) REFERENCES dentista(id)
);

CREATE TABLE clinica_dentista (
    clinica_id INTEGER NOT NULL,
    dentista_id INTEGER NOT NULL,
    PRIMARY KEY (clinica_id, dentista_id),
    FOREIGN KEY (clinica_id) REFERENCES clinica(id),
    FOREIGN KEY (dentista_id) REFERENCES dentista(id)
);

CREATE TABLE agendamento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    paciente_id INTEGER NOT NULL,
    dentista_id INTEGER NOT NULL,
    consulta_id INTEGER NOT NULL,
    clinica_id INTEGER NOT NULL,
    data DATETIME NOT NULL,
    horario DATETIME NOT NULL,
    FOREIGN KEY (paciente_id) REFERENCES paciente(id),
    FOREIGN KEY (dentista_id) REFERENCES dentista(id),
    FOREIGN KEY (consulta_id) REFERENCES consulta(id),
    FOREIGN KEY (clinica_id) REFERENCES clinica(id)
);
