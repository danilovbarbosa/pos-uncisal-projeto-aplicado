# =====================================================================
# make/vagrant.mk — Vagrant (Testes locais)
# =====================================================================

.PHONY: vagrant-check
vagrant-check: ## Verifica se Vagrant e VirtualBox estão instalados
	@command -v vagrant >/dev/null 2>&1 || { echo "ERRO: Vagrant não está instalado."; echo "Instale com: sudo apt install vagrant"; exit 1; }
	@command -v VBoxManage >/dev/null 2>&1 || { echo "ERRO: VirtualBox não está instalado."; echo "Baixe em: https://www.virtualbox.org/wiki/Downloads"; exit 1; }
	@echo "Vagrant e VirtualBox estão instalados: ✓"

.PHONY: vagrant-up
vagrant-up: ## Inicia a VM Vagrant com provisionamento completo
	cd $(VAGRANT_DIR) && ./bootstrap.sh

.PHONY: vagrant-up-clean
vagrant-up-clean: ## Destrói e recria a VM Vagrant
	cd $(VAGRANT_DIR) && ./bootstrap.sh --clean

.PHONY: vagrant-up-no-provision
vagrant-up-no-provision: ## Cria VM Vagrant sem provisionamento
	cd $(VAGRANT_DIR) && ./bootstrap.sh --skip-provision

.PHONY: vagrant-ssh
vagrant-ssh: ## Acessa a VM Vagrant via SSH
	cd $(VAGRANT_DIR) && vagrant ssh

.PHONY: vagrant-provision
vagrant-provision: ## Reexecuta o provisionamento na VM Vagrant
	cd $(VAGRANT_DIR) && vagrant provision

.PHONY: vagrant-halt
vagrant-halt: ## Para a VM Vagrant
	cd $(VAGRANT_DIR) && vagrant halt

.PHONY: vagrant-destroy
vagrant-destroy: ## Destrói completamente a VM Vagrant
	cd $(VAGRANT_DIR) && vagrant destroy -f

.PHONY: vagrant-status
vagrant-status: ## Mostra o status da VM Vagrant
	cd $(VAGRANT_DIR) && vagrant status

.PHONY: vagrant-logs
vagrant-logs: ## Mostra logs de provisionamento do Vagrant
	@cat $(VAGRANT_DIR)/.vagrant/provisioners/shell/*.log 2>/dev/null || echo "Nenhum log de provisionamento encontrado."

.PHONY: vagrant-docker-logs
vagrant-docker-logs: ## Mostra logs dos containers Docker dentro da VM Vagrant
	cd $(VAGRANT_DIR) && vagrant ssh -c "cd /opt/pos-uncisal/projeto && docker compose logs"

.PHONY: vagrant-docker-test
vagrant-docker-test: ## Roda testes Django dentro da VM Vagrant
	cd $(VAGRANT_DIR) && vagrant ssh -c "cd /opt/pos-uncisal/projeto && docker compose exec web python manage.py test"

.PHONY: vagrant-ip
vagrant-ip: ## Mostra o IP da VM Vagrant
	@cd $(VAGRANT_DIR) && vagrant ssh -c "ip addr show eth1 2>/dev/null | grep 'inet ' | awk '{print \$$2}' | cut -d/ -f1" 2>/dev/null || \
	 cd $(VAGRANT_DIR) && vagrant ssh -c "hostname -I | awk '{print \$$1}'" 2>/dev/null || \
	 echo "Não foi possível obter o IP da VM."

.PHONY: vagrant-access
vagrant-access: ## Mostra URLs de acesso à aplicação na VM Vagrant
	@IP=$$(cd $(VAGRANT_DIR) && vagrant ssh -c "ip addr show eth1 2>/dev/null | grep 'inet ' | awk '{print \$$2}' | cut -d/ -f1" 2>/dev/null || \
	 cd $(VAGRANT_DIR) && vagrant ssh -c "hostname -I | awk '{print \$$1}'" 2>/dev/null); \
	if [ -n "$$IP" ]; then \
		echo "Acesse a aplicação em:"; \
		echo "  HTTP:  http://$$IP/"; \
		echo "  HTTPS: https://$$IP/ (ignorar aviso do certificado)"; \
		echo ""; \
		echo "Credenciais: aluno / SenhaForte2025!"; \
	else \
		echo "VM não está rodando ou IP não disponível."; \
	fi