# Diagrama de Classes — ReOdonto

> Gerado com [Mermaid](https://mermaid.js.org/). Renderizável diretamente no GitHub, GitLab e na maioria das IDEs modernas.

```mermaid
classDiagram
    direction TB

    class Paciente {
        +int id
        +Text nome
        +Text email
        +String(64) email_hash
        +String(255) senha
        +Text telefone
        +Text cpf
        +String(64) cpf_hash
        +Text cep
        +Text rua
        +Text bairro
        +Text numero
        +to_dict() dict
    }

    class Dentista {
        +int id
        +String(100) nome
        +String(150) email
        +String(255) senha
        +String(20) telefone
        +String(20) cro
        +String(14) cpf_cnpj
        +to_dict() dict
    }

    class Clinica {
        +int id
        +String(100) nome
        +String(20) telefone
        +String(150) email
        +String(9) cep
        +String(150) rua
        +String(100) bairro
        +String(10) numero
        +String(100) cidade
        +String(2) estado
        +to_dict() dict
    }

    class Consulta {
        +int id
        +String(100) nome
        +Text descricao
        +Float valor
        +int duracao_minutos
        +to_dict() dict
    }

    class Agendamento {
        +int id
        +int dentista_id
        +int clinica_id
        +String(200) consulta_customizada
        +String(100) nome_paciente
        +String(20) telefone_paciente
        +DateTime data_hora
        +String(20) status
        +to_dict() dict
        +to_dict_completo() dict
    }

    class RecuperacaoSenha {
        +int id
        +String(64) email_hash
        +String(64) codigo_hash
        +DateTime expira_em
        +Boolean usado
        +DateTime criado_em
        +esta_expirado() bool
        +esta_valido() bool
    }

    %% Relacionamentos
    Agendamento "N" --> "1" Dentista : dentista_id
    Agendamento "N" --> "0..1" Clinica : clinica_id
    RecuperacaoSenha "N" ..> "1" Paciente : email_hash (lógico)

    %% Notas de segurança
    note for Paciente "Campos PII criptografados com\nFernet (AES-128-CBC).\nEmail e CPF indexados via SHA-256."
    note for RecuperacaoSenha "OTP de 6 dígitos gerado com\nsecrets.randbelow (CSPRNG).\nExpira em 15 minutos."
```

---

## Descrição das Entidades

| Entidade | Tabela | Responsabilidade |
|---|---|---|
| `Paciente` | `paciente` | Usuário final do app. Dados PII criptografados com Fernet. |
| `Dentista` | `dentista` | Profissional que cria e gerencia agendamentos. |
| `Clinica` | `clinica` | Local físico onde as consultas acontecem. |
| `Consulta` | `consulta` | Catálogo de tipos de procedimento com duração e valor. |
| `Agendamento` | `agendamento` | Slot de atendimento vinculado a dentista e clínica. Suporta pacientes walk-in. |
| `RecuperacaoSenha` | `recuperacao_senha` | Token OTP temporário para redefinição de senha via email. |

## Relacionamentos

- **Agendamento → Dentista**: cada agendamento pertence a exatamente um dentista (`dentista_id FK`).
- **Agendamento → Clinica**: cada agendamento pode estar associado a uma clínica (`clinica_id FK`, opcional).
- **RecuperacaoSenha → Paciente**: associação lógica via `email_hash` (SHA-256), sem FK explícita no banco, para proteger a privacidade.

## Segurança dos Dados

- Campos PII do `Paciente` (nome, email, telefone, CPF, endereço) são **criptografados em repouso** com AES via Fernet.
- Email e CPF possuem colunas `*_hash` (SHA-256) para permitir buscas sem expor os dados cifrados.
- Senhas armazenadas com **bcrypt** (salt aleatório por usuário).
- Tokens JWT assinados com `JWT_SECRET_KEY` (HS256).
