# =====================================================================
# Makefile — atalhos para desenvolvimento local e Docker
# =====================================================================
# Uso: `make <alvo>`. Rode `make help` para ver todos os alvos.

# ----- Configuração -----
VENV        := .venv
PYTHON      := $(VENV)/bin/python
PIP         := $(VENV)/bin/pip
MANAGE      := $(PYTHON) manage.py
COMPOSE     := docker compose

# Executa o servidor local neste host:porta
HOST        ?= 127.0.0.1
PORT        ?= 8000

.DEFAULT_GOAL := help

# ----- Meta -----
.PHONY: help
help: ## Mostra esta ajuda
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# =====================================================================
# Ambiente local (virtualenv)
# =====================================================================
.PHONY: venv
venv: ## Cria o ambiente virtual (.venv) se não existir
	@test -d $(VENV) || python3 -m venv $(VENV)
	@echo "Ambiente virtual pronto em $(VENV)"

.PHONY: install
install: venv ## Instala as dependências no virtualenv
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

.PHONY: env
env: ## Cria o .env a partir do .env.example (se ainda não existir)
	@test -f .env || cp .env.example .env
	@echo "Arquivo .env pronto. Lembre-se de definir a DJANGO_SECRET_KEY."

.PHONY: secret-key
secret-key: ## Gera uma nova SECRET_KEY do Django
	@$(PYTHON) -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

.PHONY: migrate
migrate: ## Aplica as migrações do banco de dados
	$(MANAGE) migrate

.PHONY: makemigrations
makemigrations: ## Cria novas migrações a partir dos modelos
	$(MANAGE) makemigrations

.PHONY: seed
seed: ## Cria/atualiza o usuário de demonstração
	$(MANAGE) seed_demo_user

.PHONY: superuser
superuser: ## Cria um superusuário do Django (interativo)
	$(MANAGE) createsuperuser

.PHONY: static
static: ## Coleta os arquivos estáticos
	$(MANAGE) collectstatic --noinput

.PHONY: run
run: ## Sobe o servidor de desenvolvimento (HOST/PORT configuráveis)
	$(MANAGE) runserver $(HOST):$(PORT)

.PHONY: shell
shell: ## Abre o shell do Django
	$(MANAGE) shell

.PHONY: test
test: ## Roda a suíte de testes
	$(MANAGE) test

.PHONY: check
check: ## Verifica problemas de configuração (check --deploy)
	$(MANAGE) check --deploy

.PHONY: setup
setup: install env migrate seed ## Prepara tudo para rodar localmente
	@echo "Setup concluído. Rode 'make run' para iniciar o servidor."

# =====================================================================
# Docker + Nginx (HTTPS)
# =====================================================================
.PHONY: certs
certs: ## Gera o certificado TLS autoassinado para o Nginx
	sh nginx/generate-certs.sh localhost

.PHONY: docker-env
docker-env: ## Cria o .env.docker a partir do exemplo (se ainda não existir)
	@test -f .env.docker || cp .env.docker.example .env.docker
	@echo "Arquivo .env.docker pronto. Defina a DJANGO_SECRET_KEY."

.PHONY: build
build: ## Faz o build das imagens Docker
	$(COMPOSE) build

.PHONY: up
up: certs ## Sobe o stack (web + nginx) com build, em foreground
	$(COMPOSE) up --build

.PHONY: up-d
up-d: certs ## Sobe o stack em background (detached)
	$(COMPOSE) up --build -d

.PHONY: down
down: ## Para e remove os containers
	$(COMPOSE) down

.PHONY: down-v
down-v: ## Para os containers e remove os volumes (apaga banco/estáticos)
	$(COMPOSE) down -v

.PHONY: logs
logs: ## Acompanha os logs dos containers
	$(COMPOSE) logs -f

.PHONY: ps
ps: ## Lista o status dos containers
	$(COMPOSE) ps

.PHONY: docker-test
docker-test: ## Roda os testes dentro do container web
	$(COMPOSE) exec web python manage.py test

.PHONY: docker-shell
docker-shell: ## Abre um shell sh dentro do container web
	$(COMPOSE) exec web sh

# =====================================================================
# Limpeza
# =====================================================================
.PHONY: clean
clean: ## Remove caches Python e artefatos temporários
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete
	rm -rf .pytest_cache .ruff_cache

.PHONY: clean-all
clean-all: clean ## Limpa também o virtualenv e os estáticos coletados
	rm -rf $(VENV) staticfiles
