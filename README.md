# pos-uncisal-projeto-aplicado

Projeto Aplicado às Práticas de Mercado — Especialização em Segurança da Informação e Análise Forense.

Protótipo web em **Python + Django** com backend e frontend integrados (templates do Django), contendo:

- Uma **tela de Login**.
- Uma **página interna** (dashboard) acessível **apenas após autenticação**.
- Um **botão de Logout funcional**.

O código mitiga ativamente vulnerabilidades do [OWASP Top 10:2025](https://owasp.org/Top10/2025/).
**Inclui** Dockerização com Nginx HTTPS, Makefile e **Terraform** para deploy automático na Oracle Cloud (Always Free tier).

---

## Stack

- Python 3.10+
- Django 5.2 LTS
- Gunicorn (servidor WSGI de produção)
- argon2-cffi (hashing de senhas)
- python-dotenv (segredos via variáveis de ambiente)
- Banco: SQLite (padrão de desenvolvimento)
- Docker + Docker Compose (containers)
- Nginx (proxy reverso + terminação TLS/HTTPS)

---

## Como executar

O projeto inclui um **Makefile** que encapsula os comandos mais comuns.
Rode `make help` para ver todos os alvos disponíveis.

### Opção A — com Makefile (recomendado)

```bash
make setup    # cria o venv, instala deps, cria o .env, migra e cria o usuário demo
make run      # sobe o servidor de desenvolvimento
```

> Depois de `make setup`, gere uma SECRET_KEY com `make secret-key` e cole no `.env`.
> Ajuste o `.env` para desenvolvimento local (veja os comentários no arquivo).

### Opção B — passo a passo (manual)

```bash
# 1. Criar e ativar o ambiente virtual
python3 -m venv .venv
source .venv/bin/activate

# 2. Instalar dependências
pip install -r requirements.txt

# 3. Configurar variáveis de ambiente
cp .env.example .env
# Gere uma SECRET_KEY e cole no .env:
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
# Para rodar localmente, no .env use:
#   DJANGO_DEBUG=true
#   DJANGO_SECURE_SSL_REDIRECT=false
#   DJANGO_SESSION_COOKIE_SECURE=false
#   DJANGO_CSRF_COOKIE_SECURE=false

# 4. Aplicar migrações
python manage.py migrate

# 5. Criar o usuário de demonstração
python manage.py seed_demo_user

# 6. Subir o servidor
python manage.py runserver
```

Acesse http://127.0.0.1:8000/ — você será redirecionado para a tela de login.

> A porta do `make run` é configurável: `make run PORT=9000 HOST=0.0.0.0`.

### Credenciais de demonstração

| Usuário | Senha            |
|---------|------------------|
| `aluno` | `SenhaForte2025!` |

> As credenciais podem ser sobrescritas via variáveis de ambiente
> `DEMO_USERNAME`, `DEMO_EMAIL` e `DEMO_PASSWORD`.

### Rodar os testes

```bash
make test          # ou: python manage.py test
```

São 11 testes automatizados cobrindo o fluxo de autenticação e as mitigações de segurança descritas abaixo.

---

## 🐳 Execução com Docker + Nginx (HTTPS)

O projeto pode ser executado em containers, com **Gunicorn** servindo a aplicação
e **Nginx** como **proxy reverso** fazendo a **terminação TLS (HTTPS)**.

### Arquitetura

```
Navegador ──HTTPS(443)──▶ Nginx (proxy reverso + TLS)
                              │  http://web:8000
                              ▼
                          Gunicorn ──▶ Django (app)
Navegador ──HTTP(80)───▶ Nginx ──301──▶ HTTPS
```

- O **Nginx** termina o TLS, redireciona todo tráfego HTTP (80) para HTTPS (443)
  e serve os arquivos estáticos.
- O **Django/Gunicorn** roda numa rede interna, sem exposição direta, e reconhece
  o HTTPS pelo cabeçalho `X-Forwarded-Proto` (`SECURE_PROXY_SSL_HEADER`).

### Passos

Com o Makefile, um único comando sobe todo o stack (o certificado é gerado
automaticamente antes de iniciar):

```bash
make docker-env   # cria o .env.docker a partir do exemplo (defina a SECRET_KEY)
make up           # gera o certificado + build + sobe web e nginx
```

Ou, de forma manual:

```bash
# 1. Gerar o certificado TLS autoassinado (desenvolvimento)
sh nginx/generate-certs.sh localhost

# 2. Criar o arquivo de ambiente do Docker
cp .env.docker.example .env.docker
# Gere e cole uma SECRET_KEY no .env.docker:
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# 3. Subir o stack (build + up)
docker compose up --build
```

Acesse **https://localhost/** no navegador.

> Como o certificado é **autoassinado**, o navegador exibirá um aviso de segurança.
> Isso é esperado em desenvolvimento — aceite a exceção para prosseguir. Em produção,
> use um certificado emitido por uma CA (ex.: Let's Encrypt).

O container `web` executa automaticamente, no boot: `migrate`, `collectstatic` e a
criação do usuário de demonstração (`aluno` / `SenhaForte2025!`).

### Comandos úteis

Com o Makefile:

```bash
make up-d          # sobe o stack em background (detached)
make logs          # acompanhar logs
make ps            # status dos containers
make docker-test   # rodar os testes dentro do container
make down          # parar e remover containers
make down-v        # também remove volumes (banco e estáticos)
```

Equivalentes diretos com `docker compose`:

```bash
docker compose logs -f
docker compose exec web python manage.py test
docker compose down
docker compose down -v            # remove volumes (banco e estáticos)
```

### Certificado HTTPS

O script `nginx/generate-certs.sh` gera um par autoassinado (`localhost.crt` /
`localhost.key`, RSA 2048, válido por 365 dias, com SAN para `localhost` e
`127.0.0.1`) em `nginx/certs/`, montado no container do Nginx. Esses arquivos
**não são versionados** (ver `.gitignore`).

---

## 🛠️ Makefile (Estrutura Modular)

O `Makefile` foi modularizado seguindo boas práticas com arquivos organizados no diretório `make/`. 
Rode `make help` para ver todos os **100+ comandos** disponíveis.

### Estrutura Modular

```
.
├── Makefile                    # Arquivo principal (includes)
├── make/                       # Módulos Makefile (.mk)
│   ├── common.mk              # Configurações e variáveis compartilhadas
│   ├── help.mk                # Meta-comandos (help)
│   ├── local.mk               # Ambiente local (virtualenv)
│   ├── docker.mk              # Docker + Nginx (HTTPS)
│   ├── vagrant.mk             # Vagrant (testes locais)
│   ├── test.mk                # Testes integrados
│   └── clean.mk               # Limpeza
└── ...
```

### Comandos Principais

| Categoria | Comandos Exemplo | Descrição |
|-----------|------------------|-----------|
| **Local** | `make setup`, `make run`, `make test` | Ambiente virtualenv, Django local |
| **Docker** | `make up-d`, `make docker-test`, `make logs` | Containers com Nginx HTTPS |
| **Vagrant** | `make vagrant-up`, `make vagrant-access`, `make vagrant-docker-test` | VM de testes local |
| **Testes** | `make test-matrix`, `make test-all` | Testes multi-ambiente |
| **Utilidades** | `make secret-key`, `make certs`, `make check` | Geração de chaves, certificados, verificação |
| **Limpeza** | `make clean`, `make clean-all` | Remoção de caches e arquivos temporários |

### Fluxos de Trabalho Comuns

```bash
# Desenvolvimento local
make setup      # Prepara ambiente
make run        # Sobe servidor
make test       # Roda testes

# Docker local
make up-d       # Sobe stack em background
make docker-test # Testes em containers

# Testes Vagrant
make vagrant-up      # Inicia VM de testes
make vagrant-access  # Mostra URLs de acesso
make test-matrix     # Roda testes em todos ambientes

# Produção
make certs      # Gera certificados TLS
make check      # Verifica configuração de produção
```

> **Dica**: Use `make help` para ver a lista completa de comandos (100+).
> **Aviso**: `make down-v` e `make clean-all` são destrutivos (removem volumes/banco e virtualenv).

Mais detalhes sobre a estrutura modular em [make/README.md](./make/README.md).

---

## Estrutura do projeto

```
.
├── config/                 # Projeto Django (settings, urls, wsgi)
│   ├── settings.py         # Configurações de segurança (OWASP)
│   └── urls.py
├── accounts/               # App de autenticação
│   ├── forms.py            # SecureLoginForm (sanitização + logging)
│   ├── views.py            # LoginView, LogoutView, dashboard
│   ├── urls.py
│   ├── tests.py            # Testes de fluxo e de segurança
│   └── management/commands/seed_demo_user.py
├── templates/
│   ├── base.html
│   └── accounts/
│       ├── login.html      # Tela de login
│       └── dashboard.html  # Página interna + botão de logout
├── docker/
│   └── entrypoint.sh       # migrate + collectstatic + seed no boot
├── nginx/
│   ├── nginx.conf          # Proxy reverso + TLS (HTTPS)
│   ├── generate-certs.sh   # Gera certificado autoassinado
│   └── certs/              # Certificados locais (NÃO versionado)
├── Dockerfile              # Imagem da app (Django + Gunicorn)
├── docker-compose.yml      # Orquestra web + nginx
├── .dockerignore
├── Makefile                # Interface principal (estrutura modular)
├── make/                   # Módulos Makefile (.mk) - boas práticas
│   ├── common.mk          # Configurações e variáveis compartilhadas
│   ├── help.mk            # Meta-comandos (help)
│   ├── local.mk           # Ambiente local (virtualenv)
│   ├── docker.mk          # Docker + Nginx (HTTPS)
│   ├── vagrant.mk         # Vagrant (testes locais)
│   ├── test.mk            # Testes integrados
│   └── clean.mk           # Limpeza
├── requirements.txt
├── scripts/                # Scripts utilitários centralizados
│   ├── install-gitleaks.sh # Instalação do gitleaks
│   └── README.md           # Documentação dos scripts
├── .env.example            # Modelo de variáveis (versionado)
├── .env                    # Segredos locais (NÃO versionado)
├── .env.docker.example     # Modelo de env do Docker (versionado)
└── .env.docker             # Segredos do Docker (NÃO versionado)
├── vagrant-test/           # Ambiente de testes locais (Vagrant)
│   ├── Vagrantfile         # Configuração da VM (1 vCPU, 2GB RAM, 10GB disco)
│   ├── scripts/            # Scripts de provisionamento e otimização
│   ├── bootstrap.sh        # Inicialização rápida
│   └── README.md           # Instruções
└── terraform/              # Deploy na Oracle Cloud (OCI) - Always Free
    ├── modules/            # Módulos reutilizáveis (network, compute, cloud-init)
    └── environments/       # Ambientes hmg/prd com workspaces
```

---

## 🛡️ Mitigações OWASP Top 10:2025

Foram escolhidas e implementadas mitigações para **5 categorias** (o mínimo exigido é 3),
comprovadas por testes automatizados em `accounts/tests.py`.

### ✅ A01:2025 — Broken Access Control

Controle de acesso à página interna e proteção contra CSRF.

| Onde | Como |
|------|------|
| `accounts/views.py` → `dashboard` | Decorador `@login_required`: usuários não autenticados são redirecionados para o login. |
| `config/settings.py` → `MIDDLEWARE` | `CsrfViewMiddleware` ativo em todas as requisições. |
| `templates/accounts/login.html` e `dashboard.html` | Uso de `{% csrf_token %}` nos formulários POST. |
| `accounts/views.py` → `LogoutView` | Logout só aceita **POST**, evitando logout forçado por link/imagem (CSRF de logout). |
| `config/settings.py` | `SESSION_COOKIE_SAMESITE = "Strict"` e `CSRF_COOKIE_SAMESITE = "Strict"`. |

**Testes:** `test_dashboard_exige_login`, `test_csrf_token_presente_no_form`, `test_post_sem_csrf_e_bloqueado`, `test_logout_via_get_nao_encerra_sessao`.

---

### ✅ A05:2025 — Injection (SQL Injection e XSS)

Prevenção de injeção de SQL e de scripts (XSS).

| Onde | Como |
|------|------|
| `config/settings.py` → `DATABASES` / ORM | Todo acesso a dados usa o **ORM do Django**, que gera **consultas parametrizadas** — sem concatenação de SQL. |
| `templates/*.html` | **Auto-escaping** do template engine do Django está ativo por padrão: valores como `{{ usuario.get_username }}` são escapados, neutralizando XSS. |
| `accounts/forms.py` → `SecureLoginForm.clean_username` | **Sanitização de input**: o nome de usuário é normalizado (`strip`), limitado em tamanho e validado contra uma *allowlist* de caracteres. Payloads como `<script>...</script>` são rejeitados. |

**Testes:** `test_username_com_caracteres_invalidos_e_rejeitado`.

---

### ✅ A07:2025 — Authentication Failures

Autenticação robusta e resistente a abuso.

| Onde | Como |
|------|------|
| `config/settings.py` → `AUTH_PASSWORD_VALIDATORS` | Exige senha forte: mínimo de 10 caracteres, bloqueio de senhas comuns, apenas numéricas e similares aos dados do usuário. |
| `accounts/forms.py` → `SecureLoginForm` | Mensagens de erro **genéricas** (não revelam se o usuário existe) — dificultam enumeração de contas. |
| `accounts/views.py` | O Django **renova o ID de sessão** a cada login, prevenindo *session fixation*. |
| `config/settings.py` | `SESSION_EXPIRE_AT_BROWSER_CLOSE = True`, `SESSION_COOKIE_AGE = 1800` (30 min), sessão renovada a cada requisição. |

**Testes:** `test_login_com_credenciais_validas`, `test_login_com_senha_invalida_falha`, `test_logout_encerra_sessao`.

---

### ✅ A02:2025 — Security Misconfiguration

Configuração segura por padrão e sem segredos no código.

| Onde | Como |
|------|------|
| `config/settings.py` | `SECRET_KEY`, `DEBUG` e `ALLOWED_HOSTS` lidos de variáveis de ambiente (`.env`), **fora do controle de versão**. `DEBUG` é `False` por padrão. |
| `config/settings.py` | Cabeçalhos de segurança: `SECURE_CONTENT_TYPE_NOSNIFF`, `X_FRAME_OPTIONS = "DENY"` (anti-clickjacking), `SECURE_REFERRER_POLICY`. |
| `.gitignore` | `.env`, `.env.docker`, `db.sqlite3`, `*.log` e `nginx/certs/` são ignorados, evitando vazamento de segredos e dados. |
| `Dockerfile` | O container roda com um **usuário sem privilégios** (`app`), não como `root`. |
| `docker-compose.yml` | O container `web` **não é exposto** diretamente — só o Nginx publica as portas 80/443. |
| Verificação | `python manage.py check --deploy` retorna **0 problemas** com as flags de produção ativas. |

**Testes:** `test_cabecalhos_de_seguranca`.

---

### ✅ A04:2025 — Cryptographic Failures

Armazenamento seguro de credenciais e transporte protegido.

| Onde | Como |
|------|------|
| `config/settings.py` → `PASSWORD_HASHERS` | Senhas armazenadas com **Argon2** (algoritmo recomendado), nunca em texto puro. |
| `config/settings.py` | Fora de `DEBUG`: `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE` e **HSTS** (`SECURE_HSTS_SECONDS` de 1 ano) forçam HTTPS. |
| `nginx/nginx.conf` | O **Nginx** termina o TLS e **redireciona HTTP (80) → HTTPS (443)**, garantindo tráfego cifrado. |
| `config/settings.py` | `SESSION_COOKIE_HTTPONLY = True` protege o cookie de sessão contra leitura por JavaScript. |

**Testes:** `test_senha_armazenada_com_argon2`.
**Validação Docker:** cookie `csrftoken` servido com flag `Secure` e header `Strict-Transport-Security` presente na resposta HTTPS.

---

### ➕ Bônus — A09:2025 — Security Logging and Alerting Failures

Registro de eventos de segurança.

| Onde | Como |
|------|------|
| `config/settings.py` → `LOGGING` | Loggers `django.security` e `accounts.security` gravam em console e no arquivo `security.log`. |
| `accounts/forms.py` / `accounts/views.py` | Registro de **logins bem-sucedidos, falhas de autenticação e logouts**. |

---

## Resumo das categorias escolhidas

As **3 categorias mínimas obrigatórias** atendidas (e comprovadas por teste) são:

1. **A01:2025 — Broken Access Control**
2. **A05:2025 — Injection**
3. **A07:2025 — Authentication Failures**

Adicionalmente, o projeto também cobre **A02:2025 (Security Misconfiguration)**,
**A04:2025 (Cryptographic Failures)** e **A09:2025 (Security Logging and Alerting Failures)**.

---

## ☁️ Deploy na Oracle Cloud (OCI) com Terraform Modular

O projeto inclui uma configuração **Terraform modular** com workspaces **hmg** (homologação) e **prd** (produção) para provisionar instâncias **Always Free**
na Oracle Cloud Infrastructure (OCI). Cada ambiente instala Docker automaticamente e sobe o stack com HTTPS.

### Estrutura modular

Veja a pasta [`terraform/`](./terraform/) para o código completo:

```
terraform/
├── modules/                     # Módulos reutilizáveis
│   ├── network/                 # VCN, subnet, security list, internet gateway
│   ├── compute/                 # Instância A1, data source Ubuntu ARM
│   └── cloud-init/              # Geração do user_data (cloud-init)
├── environments/                # Ambientes separados
│   ├── hmg/                     # Homologação
│   └── prd/                     # Produção
├── provider.tf                  # Provider OCI comum
└── versions.tf                  # Versões do Terraform
```

### Como usar (escolha um ambiente)

1. **Crie uma conta OCI** e gere as credenciais API (tenancy, user, fingerprint, chave privada).
2. **Fork** este repositório (ou atualize a URL em `git_repo_url`).
3. **Escolha o ambiente**:
   - **Homologação (hmg)**: CIDRs `10.0.0.0/16` (VCN), `10.0.1.0/24` (subnet)
   - **Produção (prd)**: CIDRs `10.10.0.0/16` (VCN), `10.10.1.0/24` (subnet)
4. **Copie** o arquivo de exemplo de variáveis:

```bash
cd terraform/environments/hmg   # ou prd
cp terraform.tfvars.example terraform.tfvars
```

5. **Preencha** `terraform.tfvars` com suas credenciais OCI, chave pública SSH e URL do repositório.
6. **Execute**:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

O cloud‑init levará **3‑5 minutos** para instalar Docker, clonar o repositório, gerar o
certificado autoassinado e subir o stack. Após a conclusão, acesse **https://SEU_IP/**.

### Recursos do Always Free (2026)

- **VM.Standard.A1.Flex** (Ampere ARM): até **2 OCPUs** e **12 GB RAM** por instância.
- **200 GB** de armazenamento de block volume.
- **2 IPs públicos** por tenancy.
- **10 TB/mês** de tráfego de saída.

A configuração padrão usa **2 OCPUs** e **8 GB RAM**, dentro dos limites gratuitos.

Mais detalhes em [terraform/README.md](./terraform/README.md).

---

## 🖥️ Testes Locais com Vagrant (Emulação do OCI)

Para testar a infraestrutura localmente antes de implantar na OCI, o projeto inclui
um ambiente **Vagrant** que emula a VM OCI com as mesmas configurações de segurança.

### Estrutura

```
vagrant-test/
├── Vagrantfile                    # Configuração da VM (1 vCPU, 2GB RAM, 10GB disco)
├── scripts/
│   ├── resource_optimization.sh   # Otimizações para recursos limitados
│   ├── security_hardening.sh     # Hardening idêntico ao cloud-init OCI
│   └── deploy_app.sh             # Deploy da aplicação Django+Nginx com limites
├── bootstrap.sh                   # Script de inicialização rápido
└── README.md                      # Instruções detalhadas
```

### Como usar

1. **Instale os pré-requisitos**:
   ```bash
   # Ubuntu/Debian
   sudo apt install vagrant virtualbox
   ```

2. **Inicie o ambiente** (via Makefile recomendado):
   ```bash
   make vagrant-up
   ```

3. **Acesse a aplicação**:
   ```bash
   make vagrant-access  # Mostra URLs automaticamente
   ```
   - HTTP: `http://<IP_DA_VM>/`
   - HTTPS: `https://<IP_DA_VM>/` (ignore o aviso do certificado autoassinado)

4. **Credenciais**: `aluno` / `SenhaForte2025!`

### Benefícios

- **Teste local**: Valide toda a infraestrutura antes de subir na OCI
- **Recursos otimizados**: 1 vCPU, 2GB RAM, 10GB disco (leve para máquinas modestas)
- **Segurança idêntica**: Mesmo hardening SSH, UFW, fail2ban, atualizações automáticas
- **Custo zero**: Testes locais sem consumir recursos do Always Free tier
- **Desenvolvimento**: Ambiente consistente e reproduzível para toda a equipe
- **Otimizações**: Swap, limites Docker, remoção de pacotes não essenciais

Mais detalhes em [vagrant-test/README.md](./vagrant-test/README.md).

---

## 🎯 Melhorias e Recursos Adicionais

O projeto evoluiu para incluir recursos avançados de DevOps e segurança:

### **Infraestrutura como Código (IaC)**
- **Terraform modular** com workspaces hmg/prd
- **Módulos reutilizáveis**: network, compute, cloud-init
- **Ambientes isolados**: homologação e produção separados
- **Oracle Cloud Always Free**: configuração otimizada para recursos gratuitos

### **Automação e DevOps**
- **Makefile modular** (boas práticas): 7 módulos `.mk` no diretório `make/`
- **100+ comandos** via `make help` para todas as operações
- **Testes multi-ambiente**: local, Docker, Vagrant com `make test-matrix`
- **Fluxos de trabalho unificados**: desenvolvimento → teste → produção

### **Segurança Aprimorada**
- **Hardening completo**: SSH, UFW, fail2ban, atualizações automáticas
- **Cloud-init seguro**: configurações idênticas entre Vagrant e OCI
- **OWASP Top 10:2025**: 5 categorias mitigadas (3 obrigatórias + 2 bônus)
- **Monitoramento**: verificações periódicas de segurança

### **Ambientes de Teste**
- **Vagrant otimizado**: 1 vCPU, 2GB RAM, 10GB disco (máquinas modestas)
- **Otimizações específicas**: swap, limites Docker, remoção de pacotes não essenciais
- **Testes locais completos**: infraestrutura idêntica à OCI sem custos

### **Documentação Completa**
- **README principal**: visão geral e guias de uso - [README.md](./README.md)
- **Documentação integrada**: visão completa das integrações - [docs/DOCUMENTACAO-INTEGRADA.md](./docs/DOCUMENTACAO-INTEGRADA.md)
- **Documentação de segurança**: hooks Git e gitleaks - [docs/SECURITY-HOOKS.md](./docs/SECURITY-HOOKS.md)
- **Changelog**: histórico de atualizações - [docs/DOCUMENTACAO-CHANGELOG.md](./docs/DOCUMENTACAO-CHANGELOG.md)
- **Documentação especializada**:
  - `make/README.md` → Estrutura modular do Makefile - [make/README.md](./make/README.md)
  - `vagrant-test/README.md` → Ambiente de testes local - [vagrant-test/README.md](./vagrant-test/README.md)
  - `terraform/README.md` → Deploy na Oracle Cloud - [terraform/README.md](./terraform/README.md)

---

## Observações de produção

Para implantar em produção, ajuste o `.env` (ou `.env.docker` no stack Docker):

```env
DJANGO_DEBUG=false
DJANGO_ALLOWED_HOSTS=seu-dominio.com
DJANGO_SESSION_COOKIE_SECURE=true
DJANGO_CSRF_COOKIE_SECURE=true
DJANGO_CSRF_TRUSTED_ORIGINS=https://seu-dominio.com
# Atrás do Nginx, o próprio proxy redireciona HTTP->HTTPS:
DJANGO_SECURE_SSL_REDIRECT=false
```

Recomendações adicionais:

- **Certificado TLS real**: substitua o certificado autoassinado por um emitido
  por uma CA confiável (ex.: Let's Encrypt) em `nginx/certs/`.
- **Banco de dados robusto**: troque o SQLite por PostgreSQL para produção.
- O stack Docker já usa **Gunicorn** (WSGI de produção) atrás do **Nginx** com HTTPS.
