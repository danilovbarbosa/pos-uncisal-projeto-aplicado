# =====================================================================
# make/local.mk — Ambiente local (virtualenv)
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

.PHONY: check
check: ## Verifica problemas de configuração (check --deploy)
	$(MANAGE) check --deploy

.PHONY: setup
setup: install env migrate seed ## Prepara tudo para rodar localmente
	@echo "Setup concluído. Rode 'make run' para iniciar o servidor."