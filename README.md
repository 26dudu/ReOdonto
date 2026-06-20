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

A estrutura inicial do backend segue obrigatoriamente o seguinte padrão:

```
backend/
├── controllers/
├── models/
├── repositories/
├── services/
├── database/
│   └── create_database.sql
└── demais arquivos do framework
```

**Responsabilidade de cada pasta:**

| Pasta | Responsabilidade |
|---|---|
| `controllers` | Receber as requisições da API e retornar as respostas |
| `services` | Implementar os casos de uso e regras da aplicação |
| `models` | Representar as entidades e operações básicas ligadas ao banco de dados |
| `repositories` | Concentrar consultas mais específicas ou operações que extrapolam o CRUD básico |
| `database` | Guardar o arquivo de criação do banco de dados e suas tabelas |

### Estrutura mínima esperada

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

## Como executar

> _Em breve: instruções de instalação e execução do frontend (Flutter) e do backend._

## Nome dos participantes

- Eduardo Aquino
- Lucas Caldas
- Arthur Augusto
- Yslan Cirilo
