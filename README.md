# airflow-dgb

Template [Copier](https://copier.readthedocs.io/) para ambiente Airflow local (Astro CLI) nos repositórios DGB.

## O que é

Gera um diretório `airflow/` padronizado em qualquer repo que tenha DAGs, permitindo rodar e testar DAGs localmente via [Astro CLI](https://docs.astronomer.io/astro/cli/overview) sem depender do Cloud Composer.

## Uso

### Criar ambiente em um repo novo

```bash
cd meu-repo-com-dags/
copier copy gh:destaquesgovbr/airflow-dgb .
```

O Copier fará perguntas interativas (nome do projeto, dependências, etc.) e gerará o diretório `airflow/` com toda a estrutura.

### Atualizar um repo existente

Quando este template for atualizado (nova versão do Runtime, novos padrões):

```bash
cd meu-repo-com-dags/
copier update
```

O Copier aplica as mudanças preservando customizações locais.

### Ver versões em uso

```bash
./scripts/check-versions.sh
```

## Estrutura gerada

```
repo/
├── .copier-answers.yml     # Versão do template + respostas (commitado)
└── airflow/
    ├── Dockerfile           # Astro Runtime image
    ├── requirements.txt     # Python deps
    ├── packages.txt         # OS deps
    ├── .astro/config.yaml   # Config do projeto Astro
    ├── .env.example         # Template de variáveis
    ├── .airflowignore
    ├── .dockerignore
    ├── CLAUDE.md            # Docs para agentes AI
    ├── README.md            # Docs para humanos
    ├── dags -> ../dags      # Symlink (criado automaticamente)
    ├── plugins/
    ├── include/
    └── tests/
```

## Variáveis do template

| Variável | Default | Descrição |
|----------|---------|-----------|
| `project_name` | — | Nome do repo (ex: `data-science`) |
| `astro_runtime_version` | `3.0-14` | Tag da imagem Astro Runtime |
| `python_requirements` | `psycopg2-binary>=2.9.9` | Deps Python (uma por linha) |
| `postgres_connection` | `postgresql://USER:PASS@HOST:5432/govbrnews` | Connection string **de exemplo** para .env.example (só placeholders; validado) |
| `extra_env_vars` | — | Vars adicionais para .env.example (só placeholders) |

> ⚠️ `airflow/.env.example` e `.copier-answers.yml` são **versionados**: responda só com placeholders.
> Credenciais reais vão no `airflow/.env` (gitignored), lidas do Secret Manager.
| `has_plugins` | `false` | Tem plugins em `src/`? |
| `plugin_modules` | — | Módulos src/ (se has_plugins=true) |
| `airflowignore_extras` | — | Padrões adicionais para .airflowignore |

## Repos que usam este template

| Repo | Status |
|------|--------|
| data-science | Pendente adoção |
| activitypub-server | Pendente adoção |
| scraper | Futuro |
| embeddings | Futuro |
| data-publishing | Futuro |

## Pré-requisitos

- [Copier](https://copier.readthedocs.io/) >= 9.0.0: `pipx install copier`
- [Docker](https://docs.docker.com/get-docker/)
- [Astro CLI](https://docs.astronomer.io/astro/cli/install-cli): `curl -sSL install.astronomer.io | sudo bash -s`
