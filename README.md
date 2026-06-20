# ReOdonto

App para gerenciar a realocação de clientes de uma clínica odontológica, permitindo reorganizar consultas entre horários, cadeiras e dentistas disponíveis de forma rápida e organizada.

## Tecnologias utilizadas

- **Flutter** — front-end, interface para recepcionistas e atendentes acompanharem e remanejarem os agendamentos.
- **Dart** — back-end (API/servidor), responsável pelas regras de negócio e pela comunicação com o banco de dados.
- **MySQL** — banco de dados, armazenamento dos dados de clientes, dentistas, horários e consultas.

## Estrutura do repositório

O repositório está organizado em dois diretórios principais — `frontend` e `backend` — para deixar claro onde fica cada parte do sistema e preparar o projeto para as próximas etapas de desenvolvimento.

### `frontend/`

Reservado para o desenvolvimento da interface do sistema: as telas e os recursos visuais usados pelo usuário.

### `backend/`

Contém a versão inicial do framework escolhido para o desenvolvimento da API Web.


```
ReOdonto/
├── frontend/
└── backend/
    ├── controllers/
    ├── models/
    ├── repositories/
    ├── services/
    └── database/
        └── create_database.sql
```


## Nome dos participantes

- Eduardo Aquino
- Lucas Caldas
- Arthur Augusto
- Yslan Cirilo
