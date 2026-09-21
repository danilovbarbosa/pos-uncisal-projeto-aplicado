# =====================================================================
# make/docker.mk — Docker + Nginx (HTTPS)
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