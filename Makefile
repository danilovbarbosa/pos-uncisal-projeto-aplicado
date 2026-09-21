# =====================================================================
# Makefile — atalhos para desenvolvimento local e Docker (estrutura modular)
# =====================================================================
# Uso: `make <alvo>`. Rode `make help` para ver todos os alvos.

.DEFAULT_GOAL := help

# Inclui todos os módulos
include make/common.mk   # Configurações e variáveis compartilhadas
include make/help.mk     # Meta-comandos (help)
include make/local.mk    # Ambiente local (virtualenv)
include make/docker.mk   # Docker + Nginx (HTTPS)
include make/vagrant.mk  # Vagrant (testes locais)
include make/test.mk     # Testes integrados
include make/security.mk # Segurança e gitleaks
include make/clean.mk    # Limpeza