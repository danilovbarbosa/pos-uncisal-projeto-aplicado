"""
Django settings for config project.

Configurações endurecidas para mitigar categorias do OWASP Top 10:2025.
Consulte o README.md para o mapeamento detalhado de cada mitigação.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

# Carrega variáveis de ambiente de um arquivo .env (fora do controle de versão).
# --- OWASP A02:2025 (Security Misconfiguration) / A04:2025 (Cryptographic Failures) ---
# Segredos NÃO ficam no código-fonte; são lidos do ambiente.
load_dotenv(BASE_DIR / ".env")


def env_bool(name: str, default: bool = False) -> bool:
    """Lê uma variável booleana do ambiente de forma segura."""
    value = os.environ.get(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def env_list(name: str, default=None):
    """Lê uma lista separada por vírgulas do ambiente."""
    value = os.environ.get(name)
    if not value:
        return default or []
    return [item.strip() for item in value.split(",") if item.strip()]


# --- OWASP A02:2025 (Security Misconfiguration) ---
# A SECRET_KEY vem do ambiente. Em desenvolvimento, se não houver .env,
# usamos um valor efêmero apenas para o servidor local subir — nunca em produção.
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "dev-only-insecure-key-change-me")

# DEBUG desligado por padrão. Só é ligado explicitamente via .env em dev.
DEBUG = env_bool("DJANGO_DEBUG", default=False)

# Em produção o host precisa ser declarado explicitamente.
ALLOWED_HOSTS = env_list("DJANGO_ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

# Origens confiáveis para requisições CSRF (usado atrás de proxy/HTTPS).
CSRF_TRUSTED_ORIGINS = env_list("DJANGO_CSRF_TRUSTED_ORIGINS", default=[])


# Application definition

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "accounts",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    # --- OWASP A01:2025 (Broken Access Control) — proteção contra CSRF ---
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    # --- OWASP A02:2025 — proteção contra clickjacking (X-Frame-Options) ---
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
            # Auto-escaping do template engine é ligado por padrão.
            # --- OWASP A05:2025 (Injection) — previne XSS ---
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"


# Database
# O ORM do Django usa consultas parametrizadas por padrão.
# --- OWASP A05:2025 (Injection) — previne SQL Injection ---
# O caminho do banco pode ser sobrescrito via env (ex.: volume Docker).
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.environ.get("DJANGO_DB_PATH", BASE_DIR / "db.sqlite3"),
    }
}


# Password validation
# --- OWASP A07:2025 (Authentication Failures) ---
# Exige senhas fortes; bloqueia senhas comuns, curtas, numéricas e similares ao usuário.
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 10},
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

# --- OWASP A04:2025 (Cryptographic Failures) ---
# Armazenamento de senhas usando Argon2 (recomendado), com PBKDF2 como fallback.
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher",
    "django.contrib.auth.hashers.ScryptPasswordHasher",
]


# Internationalization
LANGUAGE_CODE = "pt-br"
TIME_ZONE = "America/Maceio"
USE_I18N = True
USE_TZ = True


# Static files
STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"


# =====================================================================
# Configurações de autenticação e sessão
# =====================================================================
LOGIN_URL = "accounts:login"
LOGIN_REDIRECT_URL = "accounts:dashboard"
LOGOUT_REDIRECT_URL = "accounts:login"

# --- OWASP A07:2025 (Authentication Failures) ---
# Sessão expira ao fechar o navegador e tem tempo de vida limitado.
SESSION_EXPIRE_AT_BROWSER_CLOSE = True
SESSION_COOKIE_AGE = 60 * 30  # 30 minutos
SESSION_SAVE_EVERY_REQUEST = True  # renova a expiração a cada requisição ativa

# --- OWASP A01:2025 (Broken Access Control) / A04:2025 ---
# Cookies de sessão e CSRF protegidos contra acesso via JavaScript e envio cross-site.
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Strict"
CSRF_COOKIE_HTTPONLY = False  # o template precisa ler o token; o valor em si já é aleatório
CSRF_COOKIE_SAMESITE = "Strict"


# =====================================================================
# Cabeçalhos e transporte seguros
# --- OWASP A02:2025 (Security Misconfiguration) / A04:2025 (Cryptographic Failures) ---
# =====================================================================
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "same-origin"
X_FRAME_OPTIONS = "DENY"

# Ativados somente fora do modo DEBUG (ambiente com HTTPS real).
SECURE_SSL_REDIRECT = env_bool("DJANGO_SECURE_SSL_REDIRECT", default=not DEBUG)
SESSION_COOKIE_SECURE = env_bool("DJANGO_SESSION_COOKIE_SECURE", default=not DEBUG)
CSRF_COOKIE_SECURE = env_bool("DJANGO_CSRF_COOKIE_SECURE", default=not DEBUG)

# HSTS: força HTTPS no navegador por 1 ano (apenas em produção/HTTPS).
if not DEBUG:
    SECURE_HSTS_SECONDS = 60 * 60 * 24 * 365
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    # Respeita o cabeçalho do proxy reverso ao detectar HTTPS.
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")


# =====================================================================
# Logging de segurança
# --- OWASP A09:2025 (Security Logging and Alerting Failures) ---
# Registra tentativas de login e eventos de segurança do Django.
# =====================================================================
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "[{asctime}] {levelname} {name}: {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
        "security_file": {
            "class": "logging.FileHandler",
            "filename": BASE_DIR / "security.log",
            "formatter": "verbose",
        },
    },
    "loggers": {
        # Eventos de segurança do próprio Django (ex.: host inválido, CSRF).
        "django.security": {
            "handlers": ["console", "security_file"],
            "level": "INFO",
            "propagate": False,
        },
        # Logger da aplicação para eventos de autenticação.
        "accounts.security": {
            "handlers": ["console", "security_file"],
            "level": "INFO",
            "propagate": False,
        },
    },
}
