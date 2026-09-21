# =====================================================================
# Makefile.config — Configurações e variáveis compartilhadas
# =====================================================================

# ----- Configurações básicas -----
VENV        := .venv
PYTHON      := $(VENV)/bin/python
PIP         := $(VENV)/bin/pip
MANAGE      := $(PYTHON) manage.py
COMPOSE     := docker compose

# Configurações de execução local
HOST        ?= 127.0.0.1
PORT        ?= 8000

# Diretórios
VAGRANT_DIR := vagrant-test

# Meta
.DEFAULT_GOAL := help

# ----- Funções auxiliares -----
define print_help
	@echo "Comandos disponíveis:"
	@echo ""
	@grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Use 'make <comando>' para executar. Ex: 'make setup'"
endef