# =====================================================================
# make/clean.mk — Limpeza
# =====================================================================

.PHONY: clean
clean: ## Remove caches Python e artefatos temporários
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete
	rm -rf .pytest_cache .ruff_cache

.PHONY: clean-all
clean-all: clean ## Limpa também o virtualenv e os estáticos coletados
	rm -rf $(VENV) staticfiles