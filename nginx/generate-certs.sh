#!/bin/sh
# =====================================================================
# Gera um certificado TLS autoassinado para uso LOCAL/DESENVOLVIMENTO.
# NÃO use este certificado em produção — obtenha um de uma CA (ex.: Let's Encrypt).
# =====================================================================
set -e

CERT_DIR="$(dirname "$0")/certs"
DOMAIN="${1:-localhost}"

mkdir -p "$CERT_DIR"

if [ -f "$CERT_DIR/localhost.crt" ] && [ -f "$CERT_DIR/localhost.key" ]; then
  echo "Certificado já existe em $CERT_DIR. Nada a fazer."
  exit 0
fi

echo "==> Gerando certificado autoassinado para '$DOMAIN'..."
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$CERT_DIR/localhost.key" \
  -out "$CERT_DIR/localhost.crt" \
  -days 365 \
  -subj "/C=BR/ST=Alagoas/L=Maceio/O=UNCISAL/OU=PosSeguranca/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:localhost,IP:127.0.0.1"

echo "==> Certificado gerado em: $CERT_DIR"
echo "    - localhost.crt"
echo "    - localhost.key"
