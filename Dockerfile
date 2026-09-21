# =====================================================================
# Imagem do serviço web (Django + Gunicorn)
# =====================================================================
FROM python:3.12-slim AS base

# Boas práticas: sem .pyc, saída sem buffer, pip sem cache.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Dependências de sistema mínimas para compilar argon2-cffi e afins.
RUN apt-get update \
    && apt-get install --no-install-recommends -y build-essential libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Instala as dependências Python primeiro (melhor cache de camadas).
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copia o código da aplicação.
COPY . .

# Cria um usuário sem privilégios (OWASP A02:2025 — não rodar como root).
RUN addgroup --system app \
    && adduser --system --ingroup app app \
    && mkdir -p /app/staticfiles /app/data \
    && chown -R app:app /app

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER app

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Gunicorn como servidor WSGI de produção.
CMD ["gunicorn", "config.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "3", \
     "--timeout", "60", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
