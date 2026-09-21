#!/bin/bash
set -e

echo "=== CONFIGURAÇÃO DE SEGURANÇA (Equivalente ao cloud-init OCI) ==="

# Atualizações do sistema
echo "Atualizando pacotes..."
apt-get update
apt-get upgrade -y

# Instalação de pacotes essenciais (similar ao cloud-init)
echo "Instalando pacotes essenciais..."
apt-get install -y \
  git \
  docker.io \
  docker-compose-plugin \
  fail2ban \
  ufw \
  unattended-upgrades \
  curl \
  wget \
  vim \
  net-tools

# Configuração do Docker
echo "Configurando Docker..."
usermod -aG docker vagrant
systemctl enable docker
systemctl start docker

# Hardening do SSH
echo "Configurando hardening do SSH..."
mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# Desabilita login por root
PermitRootLogin no

# Desabilita autenticação por senha (usa apenas chaves SSH)
PasswordAuthentication no

# Desabilita autenticação vazia por senha
PermitEmptyPasswords no

# Desabilita autenticação por GSSAPI (menos comum)
GSSAPIAuthentication no

# Limita tentativas de login
MaxAuthTries 3

# Tempo de login
LoginGraceTime 60

# Usuários permitidos (apenas vagrant para acesso local)
AllowUsers vagrant

# Desabilita encaminhamento X11 (não necessário)
X11Forwarding no

# Configurações de criptografia
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
EOF

# Configuração do UFW (firewall)
echo "Configurando UFW (firewall)..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw reload

# Configuração do fail2ban
echo "Configurando fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
bantime = 3600
findtime = 600
maxretry = 3
banaction = ufw
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 5
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Atualizações automáticas de segurança
echo "Configurando atualizações automáticas..."
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

systemctl enable unattended-upgrades
systemctl start unattended-upgrades

# Desabilita serviços não essenciais
echo "Desabilitando serviços não essenciais..."
systemctl disable avahi-daemon 2>/dev/null || true
systemctl stop avahi-daemon 2>/dev/null || true

# Script de verificação periódica de segurança
echo "Configurando monitoramento de segurança..."
mkdir -p /opt/security_checks

cat > /opt/security_checks/check_security.sh << 'EOF'
#!/bin/bash
# Script de verificação periódica de segurança
LOG_FILE="/var/log/security_check.log"

echo "$(date): Iniciando verificação de segurança" >> $LOG_FILE

# Verifica se UFW está ativo
if ! ufw status | grep -q "Status: active"; then
    echo "$(date): ALERTA: UFW não está ativo" >> $LOG_FILE
    ufw --force enable
fi

# Verifica se fail2ban está rodando
if ! systemctl is-active --quiet fail2ban; then
    echo "$(date): ALERTA: fail2ban não está rodando" >> $LOG_FILE
    systemctl restart fail2ban
fi

# Verifica se há atualizações de segurança pendentes
if apt list --upgradable 2>/dev/null | grep -q security; then
    echo "$(date): ALERTA: Atualizações de segurança pendentes" >> $LOG_FILE
    unattended-upgrade --dry-run
fi

# Verifica tentativas de login SSH falhas
RECENT_FAILS=$(grep "Failed password" /var/log/auth.log | grep "$(date +'%b %d')" | wc -l)
if [ $RECENT_FAILS -gt 10 ]; then
    echo "$(date): ALERTA: $RECENT_FAILS tentativas de login SSH falhas hoje" >> $LOG_FILE
fi

echo "$(date): Verificação de segurança concluída" >> $LOG_FILE
EOF

chmod +x /opt/security_checks/check_security.sh

# Adiciona cron para verificação diária
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/security_checks/check_security.sh") | crontab -

# Limpeza periódica de containers Docker
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/docker system prune -f --filter \"until=72h\"") | crontab -

# Reinicia SSH com novas configurações
echo "Reiniciando serviço SSH..."
systemctl restart sshd

echo "=== CONFIGURAÇÃO DE SEGURANÇA CONCLUÍDA ==="
echo "Configurações aplicadas:"
echo " - SSH hardening (apenas chaves, root desabilitado)"
echo " - UFW firewall (portas 22,80,443)"
echo " - fail2ban (proteção contra brute-force)"
echo " - Atualizações automáticas de segurança"
echo " - Monitoramento periódico"