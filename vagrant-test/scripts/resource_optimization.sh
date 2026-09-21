#!/bin/bash
set -e

echo "=== OTIMIZAÇÃO PARA RECURSOS LIMITADOS (1 vCPU, 2GB RAM) ==="

# Otimizações de memória e swap
echo "Configurando swap para recursos limitados..."
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "Swap de 1GB configurado."
fi

# Otimizações do sistema para baixa memória
echo "Ajustando parâmetros do kernel para baixa memória..."
cat >> /etc/sysctl.conf << 'EOF'
# Otimizações para memória limitada
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
EOF

sysctl -p

# Limita uso de recursos do Docker (para não consumir toda a memória)
echo "Configurando limites do Docker..."
if [ -f /etc/docker/daemon.json ]; then
    echo "Arquivo daemon.json do Docker já existe. Preservando configurações."
else
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
EOF
fi

# Reinicia Docker com novas configurações
systemctl restart docker

# Otimizações do apt para usar menos memória
echo "Configurando apt para uso otimizado de memória..."
cat > /etc/apt/apt.conf.d/99memory-optimizations << 'EOF'
# Limita uso de memória do apt
Acquire::Languages "none";
Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::AutoRemove::SuggestsImportant "false";
APT::AutoRemove::RecommendsImportant "false";
EOF

# Configura limite de memória para processos do sistema
echo "Configurando systemd memory limits..."
mkdir -p /etc/systemd/system.conf.d/
cat > /etc/systemd/system.conf.d/10-memory-limits.conf << 'EOF'
[Manager]
DefaultMemoryAccounting=yes
DefaultMemoryMin=512M
DefaultMemoryHigh=1.5G
DefaultMemoryMax=1.8G
TasksMax=512
EOF

systemctl daemon-reload

# Remove pacotes não essenciais para liberar espaço
echo "Removendo pacotes não essenciais..."
apt-get purge -y \
  snapd \
  lxd \
  lxcfs \
  popularity-contest \
  apport \
  ubuntu-report \
  whoopsie \
  || true

apt-get autoremove -y --purge
apt-get clean

# Limpa cache do apt
rm -rf /var/lib/apt/lists/*
apt-get update

echo "=== OTIMIZAÇÕES APLICADAS ==="
echo "Configurações otimizadas para:"
echo " - 1 vCPU, 2GB RAM, 10GB disco"
echo " - Swap de 1GB configurado"
echo " - Docker com limites apropriados"
echo " - Systemd com limites de memória"
echo " - Pacotes não essenciais removidos"