# security.mk - Segurança e verificação de segredos

.PHONY: install-gitleaks gitleaks-detect gitleaks-protect gitleaks-test security-check

GITLEAKS_BIN ?= $(shell which gitleaks 2>/dev/null || echo "$(HOME)/bin/gitleaks")

# Instalar gitleaks
install-gitleaks:
	@echo "📥 Instalando gitleaks..."
	@./scripts/install-gitleaks.sh

# Verificar se gitleaks está instalado
check-gitleaks:
	@if [ ! -x "$(GITLEAKS_BIN)" ]; then \
		echo "❌ gitleaks não encontrado. Instale com:"; \
		echo "   make install-gitleaks"; \
		echo "   ou baixe de: https://github.com/gitleaks/gitleaks/releases"; \
		exit 1; \
	else \
		echo "✅ gitleaks encontrado: $(GITLEAKS_BIN)"; \
		echo "   Versão: $$($(GITLEAKS_BIN) version 2>/dev/null || echo 'desconhecida')"; \
	fi

# Detectar segredos no histórico
gitleaks-detect: check-gitleaks
	@echo "🔍 Verificando segredos no histórico completo..."
	@$(GITLEAKS_BIN) detect --source . -v

# Verificar segredos nos arquivos staged (pré-commit)
gitleaks-protect: check-gitleaks
	@echo "🔍 Verificando segredos nos arquivos staged..."
	@$(GITLEAKS_BIN) protect --staged -v

# Testar hooks de segredos
gitleaks-test: check-gitleaks
	@echo "🧪 Testando hooks de segredos..."
	@echo "1. Criando arquivo de teste com segredo falso..."
	@echo 'SECRET_KEY = "fake-secret-key-1234567890"' > test-secret-leak.txt
	@echo 'password = "teste123"' >> test-secret-leak.txt
	@git add test-secret-leak.txt 2>/dev/null || true
	@echo "2. Executando hook pré-commit..."
	@.git/hooks/pre-commit; EXIT_CODE=$$?; \
	git reset test-secret-leak.txt 2>/dev/null || true; \
	rm -f test-secret-leak.txt; \
	if [ $$EXIT_CODE -eq 1 ]; then \
		echo "✅ Teste PASS: Hook bloqueou commit com segredo"; \
		exit 0; \
	else \
		echo "❌ Teste FAIL: Hook não bloqueou commit"; \
		exit 1; \
	fi

# Verificação completa de segurança
security-check: gitleaks-detect
	@echo "✅ Verificação de segredos concluída"