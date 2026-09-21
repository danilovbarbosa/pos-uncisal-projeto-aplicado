# =====================================================================
# make/test.mk — Testes integrados (multi-ambiente)
# =====================================================================

.PHONY: test
test: ## Roda a suíte de testes
	$(MANAGE) test

.PHONY: test-all
test-all: test docker-test ## Roda testes em todos os ambientes (local + Docker)
	@echo "Testes concluídos em ambiente local e Docker."

.PHONY: test-vagrant
test-vagrant: ## Roda testes dentro da VM Vagrant (se estiver rodando)
	@if cd $(VAGRANT_DIR) && vagrant status | grep -q "running"; then \
		cd $(VAGRANT_DIR) && vagrant ssh -c "cd /opt/pos-uncisal/projeto && docker compose exec web python manage.py test"; \
	else \
		echo "VM Vagrant não está rodando. Execute 'make vagrant-up' primeiro."; \
		exit 1; \
	fi

.PHONY: test-matrix
test-matrix: ## Roda testes em matriz: local, Docker, Vagrant (se disponível)
	@echo "=== Executando matriz de testes ==="
	@echo "1. Ambiente local (virtualenv)..."
	@$(MAKE) test
	@echo "2. Docker local..."
	@$(MAKE) docker-test
	@if cd $(VAGRANT_DIR) && vagrant status | grep -q "running"; then \
		echo "3. VM Vagrant..."; \
		cd $(VAGRANT_DIR) && vagrant ssh -c "cd /opt/pos-uncisal/projeto && docker compose exec web python manage.py test"; \
	else \
		echo "3. VM Vagrant (pulando - não está rodando)"; \
	fi
	@echo "=== Matriz de testes concluída ==="