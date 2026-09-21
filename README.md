# pos-uncisal-projeto-aplicado

Projeto Aplicado às Práticas de Mercado — Especialização em Segurança da Informação e Análise Forense.

Protótipo web em **Python + Django** com backend e frontend integrados (templates do Django), contendo:

- Uma **tela de Login**.
- Uma **página interna** (dashboard) acessível **apenas após autenticação**.
- Um **botão de Logout funcional**.

O código mitiga ativamente vulnerabilidades do [OWASP Top 10:2025](https://owasp.org/Top10/2025/).

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

## 🛠️ Makefile

O `Makefile` reúne os comandos do dia a dia. Rode `make help` para a lista completa.

| Alvo | O que faz |
|------|-----------|
| `make setup` | Cria o venv, instala dependências, cria o `.env`, migra e cria o usuário demo |
| `make install` | Cria o venv e instala as dependências |
| `make run` | Sobe o servidor de desenvolvimento (`HOST`/`PORT` configuráveis) |
| `make test` | Roda a suíte de testes |
| `make check` | Roda `manage.py check --deploy` |
| `make migrate` / `make makemigrations` | Migrações do banco |
| `make seed` / `make superuser` | Cria usuário demo / superusuário |
| `make secret-key` | Gera uma nova `SECRET_KEY` |
| `make certs` | Gera o certificado TLS autoassinado |
| `make up` / `make up-d` | Sobe o stack Docker (foreground / background) |
| `make build` / `make down` / `make down-v` | Build / parar / parar+remover volumes |
| `make logs` / `make ps` | Logs / status dos containers |
| `make docker-test` / `make docker-shell` | Testes / shell dentro do container |
| `make clean` / `make clean-all` | Limpa caches / também venv e estáticos |

> ⚠️ `make down-v` e `make clean-all` são destrutivos (removem volumes/banco e o venv).

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
├── Makefile                # Atalhos (make help lista os alvos)
├── requirements.txt
├── .env.example            # Modelo de variáveis (versionado)
├── .env                    # Segredos locais (NÃO versionado)
├── .env.docker.example     # Modelo de env do Docker (versionado)
└── .env.docker             # Segredos do Docker (NÃO versionado)
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
