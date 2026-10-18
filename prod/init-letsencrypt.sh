#!/bin/sh
set -e

DOMAIN="projetosecposdanilo.duckdns.org"
EMAIL="teste@gmail.com"   # troque pelo seu e-mail real
STAGING=0                       # 1 = teste (sem limites); 0 = certificado real
DATA_PATH="./certbot"

if [ -f "$DATA_PATH/conf/renewal/$DOMAIN.conf" ]; then
  echo "Certificado Let's Encrypt já existe para $DOMAIN. Nada a fazer."
  exit 0
fi

mkdir -p "$DATA_PATH/conf" "$DATA_PATH/www"

echo "==> Criando certificado temporário para o nginx subir..."
docker compose run --rm --entrypoint "\
  sh -c 'mkdir -p /etc/letsencrypt/live/$DOMAIN && \
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -out /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -subj /CN=localhost'" certbot

echo "==> Subindo o nginx..."
docker compose up -d --force-recreate nginx
sleep 5

echo "==> Removendo certificado temporário..."
docker compose run --rm --entrypoint "\
  rm -rf /etc/letsencrypt/live/$DOMAIN \
         /etc/letsencrypt/archive/$DOMAIN \
         /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

STAGING_ARG=""
[ "$STAGING" = "1" ] && STAGING_ARG="--staging"

echo "==> Solicitando certificado ao Let's Encrypt para $DOMAIN..."
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $STAGING_ARG \
    -d $DOMAIN \
    --email $EMAIL --agree-tos --no-eff-email" certbot

echo "==> Recarregando o nginx..."
docker compose exec nginx nginx -s reload

echo "==> Pronto. Se usou STAGING=1, ajuste para 0, apague ./certbot/conf e rode de novo."
