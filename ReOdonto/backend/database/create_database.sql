-- create_database.sql
-- Schema atualizado — reflete os models SQLAlchemy reais do projeto.
-- ATENÇÃO: Este arquivo é apenas documentação de referência.
-- O banco é criado automaticamente pelo ORM (db.create_all()) ao iniciar app.py.

-- Paciente: dados sensíveis armazenados criptografados (Fernet AES-128).
-- email_hash e cpf_hash são SHA-256 para buscas sem expor o dado real.
CREATE TABLE IF NOT EXISTS paciente (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nome        TEXT    NOT NULL,           -- Fernet encrypted
    email       TEXT    NOT NULL,           -- Fernet encrypted
    email_hash  TEXT    NOT NULL UNIQUE,    -- SHA-256 para lookup
    senha       TEXT    NOT NULL,           -- bcrypt hash
    telefone    TEXT,                       -- Fernet encrypted
    cpf         TEXT,                       -- Fernet encrypted
    cpf_hash    TEXT    UNIQUE,             -- SHA-256 para lookup
    cep         TEXT,                       -- Fernet encrypted
    rua         TEXT,                       -- Fernet encrypted
    bairro      TEXT,                       -- Fernet encrypted
    numero      TEXT                        -- Fernet encrypted
);

CREATE INDEX IF NOT EXISTS idx_paciente_email_hash ON paciente (email_hash);
CREATE INDEX IF NOT EXISTS idx_paciente_cpf_hash   ON paciente (cpf_hash);

-- Dentista
CREATE TABLE IF NOT EXISTS dentista (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    nome      VARCHAR(100) NOT NULL,
    email     VARCHAR(150) NOT NULL UNIQUE,
    telefone  VARCHAR(20),
    cro       VARCHAR(20)
);

CREATE INDEX IF NOT EXISTS idx_dentista_email ON dentista (email);

-- Clínica
CREATE TABLE IF NOT EXISTS clinica (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nome    VARCHAR(100) NOT NULL,
    telefone VARCHAR(20),
    email   VARCHAR(150),
    cep     VARCHAR(9),
    rua     VARCHAR(150),
    bairro  VARCHAR(100),
    numero  VARCHAR(10),
    cidade  VARCHAR(100),
    estado  VARCHAR(2)
);

-- Agendamento: relaciona paciente × dentista × clínica
CREATE TABLE IF NOT EXISTS agendamento (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    paciente_id INTEGER NOT NULL REFERENCES paciente(id),
    dentista_id INTEGER NOT NULL REFERENCES dentista(id),
    consulta_customizada VARCHAR(200),  -- tipo de consulta em texto livre
    clinica_id  INTEGER NOT NULL REFERENCES clinica(id),
    data_hora   DATETIME NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'agendado'
    -- status possíveis: 'agendado', 'concluido', 'cancelado'
);

CREATE INDEX IF NOT EXISTS idx_agendamento_paciente  ON agendamento (paciente_id);
CREATE INDEX IF NOT EXISTS idx_agendamento_dentista  ON agendamento (dentista_id);
CREATE INDEX IF NOT EXISTS idx_agendamento_data_hora ON agendamento (data_hora);
