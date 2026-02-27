# Plano: airflow-dgb — Padronização do Ambiente Airflow Local

## Contexto

Temos 5 repos com DAGs Airflow (scraper, activitypub-server, data-science, embeddings, data-publishing). Dois deles (activitypub-server e data-science) já possuem ambiente local com Astro CLI, mas foram criados manualmente — ~90% do boilerplate é idêntico. Nota: data-platform **não tem DAGs** e não precisa de ambiente Airflow local.

**Objetivo**: Criar um template Copier reutilizável (`airflow-dgb`) que permita scaffoldar e atualizar o diretório `airflow/` em qualquer repo DGB com DAGs, com versionamento e observabilidade centralizados.

---

## Diagnóstico: O que é igual vs. o que varia

| Arquivo | Igual entre repos? | Observação |
|---------|-------------------|------------|
| `Dockerfile` | 100% igual | `FROM astrocrpublic.azurecr.io/runtime:3.0-14` |
| `packages.txt` | 100% igual | Vazio |
| `.dockerignore` | ~95% | Mesmos padrões |
| `.airflowignore` | ~90% | activitypub exclui `src` extra |
| `.astro/config.yaml` | Template | Só muda `project.name` |
| `include/.gitkeep` | 100% igual | Vazio |
| `dags` symlink | 100% igual | `-> ../dags` |
| **`requirements.txt`** | **Varia** | boto3, requests, etc. por repo |
| **`.env.example`** | **Varia** | Connections/vars específicas |
| **`docker-compose.override.yml`** | **Varia** | Serviços locais, volume mounts |
| **`plugins/`** | **Varia** | Symlinks para `src/` modules |
| **`CLAUDE.md`** | **Varia** | Docs específicas do repo |

---

## Abordagem: Copier Template

### Por que Copier e não as alternativas

| Alternativa | Problema |
|------------|---------|
| GitHub Template Repo | Sem mecanismo de atualização — diverge imediatamente |
| Git Submodule | Doloroso, merge friction, não cabe neste layout de diretórios |
| CLI customizada (`dgb`) | Over-engineering para ~10 arquivos, requer empacotamento/distribuição |
| Shell script | Sem memória do que gerou, sem merge inteligente em updates |

**Copier** resolve tudo:
- `copier copy` scaffolda `airflow/` com perguntas interativas
- `copier update` aplica mudanças upstream com three-way merge
- `.copier-answers.yml` rastreia versão automaticamente (observabilidade)
- Zero infraestrutura — é um `pip install copier` e um repo git

---

## Implementação

### 1. Criar repo `destaquesgovbr/airflow-dgb`

```
airflow-dgb/
├── copier.yml                     # Config + perguntas
├── template/
│   └── airflow/
│       ├── .astro/
│       │   └── config.yaml.jinja
│       ├── Dockerfile.jinja
│       ├── packages.txt
│       ├── requirements.txt.jinja
│       ├── .dockerignore
│       ├── .airflowignore.jinja
│       ├── .env.example.jinja
│       ├── include/
│       │   └── .gitkeep
│       ├── plugins/
│       │   └── .gitkeep
│       ├── tests/
│       │   └── .gitkeep
│       ├── CLAUDE.md.jinja
│       └── README.md.jinja       # Docs do ambiente + gestão via Copier
├── scripts/
│   └── check-versions.sh         # Observabilidade: versão em cada repo
└── README.md                     # Docs do template em si
```

### 2. Definir `copier.yml`

```yaml
_min_copier_version: "9.0.0"
_subdirectory: template
_skip_if_exists:
  - "airflow/docker-compose.override.yml"

project_name:
  type: str
  help: "Nome do repositório (ex: data-platform, scraper)"

astro_runtime_version:
  type: str
  default: "3.0-14"
  help: "Versão do Astro Runtime (tag da imagem Docker)"

python_requirements:
  type: str
  default: "psycopg2-binary>=2.9.9"
  help: "Dependências Python para requirements.txt (uma por linha)"
  multiline: true

postgres_connection:
  type: str
  default: "postgresql://USER:PASS@HOST:5432/govbrnews"
  help: "Connection string template para .env.example"

extra_env_vars:
  type: str
  default: ""
  help: "Variáveis de ambiente adicionais para .env.example (uma por linha)"
  multiline: true

has_plugins:
  type: bool
  default: false
  help: "Repo tem plugins em src/ para montar no Airflow?"

plugin_modules:
  type: str
  default: ""
  help: "Módulos src/ separados por vírgula (ex: news_enrichment,other_plugin)"
  when: "{{ has_plugins }}"

airflowignore_extras:
  type: str
  default: ""
  help: "Padrões adicionais para .airflowignore (um por linha)"
  multiline: true

_tasks:
  - "cd airflow && ln -sfn ../dags dags 2>/dev/null || true"
```

### 3. Arquivos template

**`Dockerfile.jinja`**:
```dockerfile
FROM astrocrpublic.azurecr.io/runtime:{{ astro_runtime_version }}
```

**`.astro/config.yaml.jinja`**:
```yaml
project:
  name: {{ project_name }}
```

**`requirements.txt.jinja`**:
```
{{ python_requirements }}
```

**`.env.example.jinja`**:
```
# Airflow Connections
AIRFLOW_CONN_POSTGRES_DEFAULT={{ postgres_connection }}
{% if extra_env_vars %}

# Variáveis adicionais
{{ extra_env_vars }}
{% endif %}
```

**`.airflowignore.jinja`**:
```
__pycache__
.git
node_modules
tests
{% if airflowignore_extras %}{{ airflowignore_extras }}{% endif %}
```

**`.dockerignore`** (estático):
```
.astro
.git
.env
airflow_settings.yaml
logs
.venv
*.db
*.cfg
```

**`CLAUDE.md.jinja`**: Documentação parametrizada com `project_name`, `astro_runtime_version`, comandos de start/stop, seção de connections. Focado em instruções para agentes AI (Claude Code).

**`README.md.jinja`**: Documentação humana do ambiente local, incluindo:
- O que é o ambiente Airflow local e para que serve
- Pré-requisitos (Docker, Astro CLI)
- Como instalar o Astro CLI
- Quick start (start, UI, trigger DAG, logs, stop)
- Estrutura de arquivos e symlinks
- Como configurar connections (.env)
- Diferenças entre ambiente local e Cloud Composer (produção)
- **Seção sobre gestão via Copier**: explica que o diretório é gerido pelo template `airflow-dgb`, como atualizar (`copier update`), o que é o `.copier-answers.yml`, e quais arquivos são safe para customizar vs. geridos pelo template
- Troubleshooting

### 4. .gitignore additions

O template também deve adicionar ao `.gitignore` do repo consumidor (ou documentar):
```
airflow/.env
airflow/logs/
```

### 5. Script de observabilidade

**`scripts/check-versions.sh`**:
```bash
#!/bin/bash
repos="scraper activitypub-server data-science embeddings data-publishing"
for repo in $repos; do
  version=$(gh api "repos/destaquesgovbr/$repo/contents/.copier-answers.yml" \
    --jq '.content' 2>/dev/null | base64 -d | grep '_commit:' | awk '{print $2}')
  printf "%-25s %s\n" "$repo" "${version:-not-using-template}"
done
```

---

## Rollout

### Fase 1: Criar o template (este PR)

1. Criar repo `airflow-dgb`
2. Implementar `copier.yml` + templates
3. Testar com `copier copy` local
4. Tag `v1.0.0`

### Fase 2: Adotar nos repos existentes

**data-science** (já tem `airflow/`):
```bash
cd data-science
copier copy gh:destaquesgovbr/airflow-dgb .
# Comparar output com airflow/ existente, ajustar template se necessário
# Commit .copier-answers.yml
```

**activitypub-server** (já tem `airflow/`):
```bash
cd activitypub-server
copier copy gh:destaquesgovbr/airflow-dgb .
# Mesmo processo
```

### Fase 3: Expandir (futuro)
- scraper, embeddings, data-publishing (repos com DAGs que ainda não têm ambiente local)

---

## Arquivos Críticos (referência)

| Arquivo existente | Uso |
|------------------|-----|
| `data-science/airflow/Dockerfile` | Referência do padrão |
| `data-science/airflow/docker-compose.override.yml` | Exemplo de volume mounts para plugins |
| `activitypub-server/airflow/docker-compose.override.yml` | Exemplo de serviço local (federation-db) |
| `activitypub-server/airflow/CLAUDE.md` | Referência para template CLAUDE.md |
| `data-science/airflow/CLAUDE.md` | Segunda referência |
| `reusable-workflows/.github/workflows/composer-deploy-dags.yml` | Deploy workflow (contexto) |

---

## Verificação

1. `copier copy` gera diretório `airflow/` funcional em repo limpo
2. `astro dev start` sobe sem erros com o output gerado
3. `copier copy` em data-science/activitypub-server produz output compatível com o existente
4. `copier update` após bump de versão do template aplica mudanças corretamente
5. `scripts/check-versions.sh` lista repos e versões
6. `.copier-answers.yml` commitado e visível via GitHub API
