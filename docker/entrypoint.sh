#!/bin/sh
set -e

echo "==> Aplicando migrações do banco de dados..."
python manage.py migrate --noinput

echo "==> Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

# Cria o usuário de demonstração (idempotente) se habilitado.
if [ "${CREATE_DEMO_USER:-true}" = "true" ]; then
  echo "==> Provisionando usuário de demonstração..."
  python manage.py seed_demo_user
fi

echo "==> Iniciando o servidor de aplicação..."
exec "$@"
