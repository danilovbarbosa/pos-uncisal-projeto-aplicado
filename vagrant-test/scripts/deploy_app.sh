#!/bin/bash
set -e

echo "=== DEPLOY DA APLICAÇÃO DJANGO + NGINX HTTPS ==="

# Diretório do projeto (sincronizado via Vagrant)
PROJECT_DIR="/opt/pos-uncisal/projeto"

# Verifica se o diretório do projeto existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERRO: Diretório do projeto não encontrado: $PROJECT_DIR"
    echo "Certifique-se de que a sincronização de pastas do Vagrant está funcionando."
    exit 1
fi

cd "$PROJECT_DIR"

echo "Diretório do projeto: $(pwd)"

# Gera o certificado TLS autoassinado (se não existir)
echo "Verificando certificado TLS..."
if [ ! -f nginx/certs/localhost.crt ]; then
    echo "Gerando certificado TLS autoassinado..."
    if [ -f "nginx/generate-certs.sh" ]; then
        sh nginx/generate-certs.sh localhost
        echo "Certificado gerado com sucesso."
    else
        echo "AVISO: Script generate-certs.sh não encontrado. Criando certificado manualmente..."
        mkdir -p nginx/certs
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/certs/localhost.key \
            -out nginx/certs/localhost.crt \
            -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=Pos Uncisal/CN=localhost" \
            -addext "subjectAltName = DNS:localhost,IP:127.0.0.1"
    fi
else
    echo "Certificado já existe."
fi

# Cria o arquivo de ambiente Docker (usando valores padrão)
echo "Configurando ambiente Docker..."
if [ ! -f .env.docker ]; then
    echo "Criando .env.docker a partir do exemplo..."
    if [ -f ".env.docker.example" ]; then
        cp .env.docker.example .env.docker
        
        # Gera uma SECRET_KEY automaticamente
        if command -v python3 >/dev/null 2>&1; then
            DJANGO_SECRET_KEY=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
            sed -i "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}|" .env.docker
            echo "SECRET_KEY gerada automaticamente."
        else
            echo "AVISO: Python3 não encontrado. Usando SECRET_KEY padrão."
            sed -i "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=vagrant-test-secret-key-change-in-production|" .env.docker
        fi
        
        # Ajusta configurações para ambiente Vagrant
        sed -i "s|^DJANGO_DEBUG=.*|DJANGO_DEBUG=true|" .env.docker
        sed -i "s|^DJANGO_ALLOWED_HOSTS=.*|DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.*,*|" .env.docker
        sed -i "s|^DJANGO_SECURE_SSL_REDIRECT=.*|DJANGO_SECURE_SSL_REDIRECT=false|" .env.docker
    else
        echo "AVISO: .env.docker.example não encontrado. Criando .env.docker básico..."
        cat > .env.docker << EOF
# Configurações Django para ambiente Vagrant
DJANGO_DEBUG=true
DJANGO_SECRET_KEY=vagrant-test-secret-key-change-in-production
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.*,*
DJANGO_SECURE_SSL_REDIRECT=false
DJANGO_SESSION_COOKIE_SECURE=false
DJANGO_CSRF_COOKIE_SECURE=false
DJANGO_CSRF_TRUSTED_ORIGINS=http://localhost,http://127.0.0.1,https://localhost,https://127.0.0.1

# Banco de dados
DJANGO_DB_PATH=/app/data/db.sqlite3

# Usuário demo
CREATE_DEMO_USER=true
DEMO_USERNAME=aluno
DEMO_EMAIL=aluno@example.com
DEMO_PASSWORD=SenhaForte2025!
EOF
    fi
else
    echo ".env.docker já existe."
fi

# Build dos containers Docker com otimização para recursos limitados
echo "Construindo containers Docker (com otimização para recursos limitados)..."
docker compose build --no-cache --progress plain

# Limita recursos dos containers para evitar sobrecarga
echo "Configurando limites de recursos para containers..."
cat > docker-compose.override.yml << 'EOF'
version: '3.8'

services:
  web:
    deploy:
      resources:
        limits:
          cpus: '0.5'  # Metade de um vCPU
          memory: 768M
        reservations:
          memory: 512M
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
  
  nginx:
    deploy:
      resources:
        limits:
          cpus: '0.3'  # 30% de um vCPU
          memory: 256M
        reservations:
          memory: 128M
EOF

# Inicia o stack Docker (web + nginx)
echo "Subindo os containers (docker compose)..."
docker compose up -d

# Aguarda os containers estarem rodando
echo "Aguardando inicialização dos containers..."
sleep 10

# Verifica se os containers estão rodando
if docker compose ps | grep -q "Up"; then
    echo "Containers Docker rodando com sucesso!"
    
    # Obtém o IP da VM
    VM_IP=$(ip addr show eth1 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    if [ -z "$VM_IP" ]; then
        VM_IP=$(hostname -I | awk '{print $1}')
    fi
    
    echo ""
    echo "================================================================"
    echo "DEPLOY CONCLUÍDO COM SUCESSO! (Recursos otimizados: 1 vCPU, 2GB RAM)"
    echo "================================================================"
    echo ""
    echo "Acesse a aplicação em:"
    echo "  HTTP:  http://${VM_IP}/"
    echo "  HTTPS: https://${VM_IP}/  (certificado autoassinado - ignore o aviso)"
    echo ""
    echo "Credenciais de teste:"
    echo "  Usuário: aluno"
    echo "  Senha: SenhaForte2025!"
    echo ""
    echo "Comandos úteis dentro da VM:"
    echo "  docker compose logs -f          # Acompanhar logs"
    echo "  docker compose ps               # Status dos containers"
    echo "  docker compose exec web python manage.py test  # Rodar testes"
    echo "  docker compose down             # Parar containers"
    echo "  docker compose down -v          # Parar e remover volumes"
    echo ""
    echo "Configurações de segurança aplicadas:"
    echo "  - SSH: apenas chaves, root desabilitado, criptografia moderna"
    echo "  - UFW: firewall ativo (portas 22,80,443)"
    echo "  - fail2ban: proteção contra brute-force"
    echo "  - Atualizações automáticas de segurança"
    echo "================================================================"
    
    # Cria um arquivo com as informações de acesso
    cat > /home/vagrant/ACCESS_INFO.txt << EOF
=== INFORMAÇÕES DE ACESSO ===
IP da VM: ${VM_IP}
HTTP: http://${VM_IP}/
HTTPS: https://${VM_IP}/ (ignorar aviso de certificado)

Credenciais:
- Usuário: aluno
- Senha: SenhaForte2025!

Comandos úteis:
- vagrant ssh                    # Acessar a VM
- docker compose logs -f         # Logs da aplicação
- docker compose exec web python manage.py test  # Testes

Este arquivo foi gerado em: $(date)
EOF
    
    echo "Informações de acesso salvas em: /home/vagrant/ACCESS_INFO.txt"
    
else
    echo "ERRO: Falha ao iniciar os containers Docker."
    echo "Verifique os logs com: docker compose logs"
    exit 1
fi