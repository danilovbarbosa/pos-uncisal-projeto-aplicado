# Vagrant Test Environment para Projeto Django + Nginx HTTPS

Este projeto Vagrant emula o ambiente OCI (Oracle Cloud) localmente para testes do projeto Django com Nginx HTTPS.

## Objetivo

Permitir testes locais da infraestrutura e deploy antes de aplicar no OCI, com:
- **Recursos otimizados**: 1 vCPU, 2GB RAM, 10GB disco (leve para máquinas modestas)
- Configurações de segurança idênticas ao cloud-init da OCI
- Mesma stack Docker (Django + Gunicorn + Nginx HTTPS) com limites de recursos
- Hardening de SSH, firewall, fail2ban
- Otimizações específicas para recursos limitados
- Ambiente isolado e reproduzível

## Pré-requisitos

1. **Vagrant** (>= 2.3.0)
   ```bash
   # Ubuntu/Debian
   sudo apt install vagrant virtualbox
   
   # macOS (com Homebrew)
   brew install --cask vagrant virtualbox
   ```

2. **VirtualBox** (>= 7.0)
   - [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)

3. **Git** e acesso ao repositório do projeto

## Estrutura

```
vagrant-test/
├── Vagrantfile                    # Configuração da VM
├── scripts/
│   ├── security_hardening.sh     # Hardening de segurança (equivalente ao cloud-init)
│   └── deploy_app.sh             # Deploy da aplicação Django+Nginx
├── config/
│   └── ssh/                      # Chaves SSH (opcional)
└── README.md
```

## Como usar

### 1. Inicializar a VM

```bash
cd vagrant-test
vagrant up
```

Isso irá:
- Baixar a imagem Ubuntu 22.04 (jammy)
- Configurar **1 vCPU, 2GB RAM, 10GB disco** (otimizado para máquinas modestas)
- Aplicar otimizações específicas para recursos limitados (swap, limites Docker, etc.)
- Aplicar hardening de segurança (SSH, UFW, fail2ban)
- Sincronizar o projeto local para `/opt/pos-uncisal/projeto`
- Fazer deploy da aplicação Django + Nginx HTTPS com limites de recursos

### 2. Acessar a aplicação

Após o `vagrant up`, o Vagrant mostrará o IP da VM e as URLs de acesso.

Para obter o IP manualmente:
```bash
vagrant ssh -c "ip addr show eth1 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1"
```

Acesse no navegador:
- **HTTP**: `http://<IP_DA_VM>/`
- **HTTPS**: `https://<IP_DA_VM>/` (ignore o aviso do certificado autoassinado)

### 3. Credenciais de teste

| Usuário | Senha            |
|---------|------------------|
| `aluno` | `SenhaForte2025!` |

### 4. Comandos úteis

```bash
# Acessar a VM
vagrant ssh

# Reexecutar provisionamento
vagrant provision

# Ver status da VM
vagrant status

# Parar a VM
vagrant halt

# Destruir a VM (remover completamente)
vagrant destroy -f

# Ver logs do provisionamento
vagrant up --debug  # Modo debug
```

### 5. Dentro da VM

```bash
# Acompanhar logs da aplicação
docker compose logs -f

# Status dos containers
docker compose ps

# Rodar testes Django
docker compose exec web python manage.py test

# Acessar container web
docker compose exec web bash

# Parar containers
docker compose down

# Parar e remover volumes
docker compose down -v
```

## Configurações de segurança aplicadas

O provisionamento aplica as mesmas configurações do cloud-init da OCI:

### 1. **Hardening do SSH**
- `PermitRootLogin no` - Login root desabilitado
- `PasswordAuthentication no` - Apenas autenticação por chaves
- `MaxAuthTries 3` - Limite de tentativas
- `AllowUsers vagrant` - Acesso restrito
- Criptografia moderna (curve25519, AES-GCM, ChaCha20)

### 2. **Firewall (UFW)**
- Portas abertas: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- Política padrão: DROP entrada, ACCEPT saída

### 3. **Fail2ban**
- Proteção contra brute-force attacks
- 3 tentativas falhas = banimento por 1 hora
- Jail para SSH DDoS

### 4. **Atualizações automáticas**
- Aplica atualizações de segurança automaticamente
- Remove dependências não utilizadas

### 5. **Monitoramento**
- Verificação diária de segurança (2:00 AM)
- Logs em `/var/log/security_check.log`
- Limpeza automática de containers antigos

## Diferenças em relação ao OCI

| Aspecto | OCI (Produção) | Vagrant (Teste) |
|---------|----------------|-----------------|
| **Arquitetura** | ARM64 (Ampere A1) | x86_64 |
| **Imagem** | Ubuntu 24.04 ARM | Ubuntu 22.04 x86 |
| **Recursos** | 2 OCPUs, 8GB RAM, 50GB disco | 1 vCPU, 2GB RAM, 10GB disco |
| **Provisão** | cloud-init | Shell scripts + otimizações |
| **Rede** | IP público real | IP local/NAT |
| **Custo** | Always Free (limites) | Local (gratuito) |
| **Performance** | Recursos dedicados | Recursos compartilhados e limitados |

## Recursos da VM

A VM foi configurada com recursos reduzidos para funcionar bem em máquinas modestas:

| Recurso | Configuração | Otimizações aplicadas |
|---------|--------------|------------------------|
| **vCPU** | 1 núcleo | Containers Docker limitados (web: 0.5 vCPU, nginx: 0.3 vCPU) |
| **RAM** | 2GB | Swap de 1GB configurado, limites de memória para systemd |
| **Disco** | 10GB | Otimizado, pacotes não essenciais removidos |
| **Rede** | Bridge DHCP | Acesso via IP local da rede |
| **Swap** | 1GB | Configurado automaticamente para evitar OOM |

### Otimizações específicas:

1. **Swap de 1GB**: Para evitar out-of-memory em máquinas com pouca RAM
2. **Limites Docker**: Containers com limites de CPU e memória
3. **Systemd limits**: Limites de memória para processos do sistema
4. **Apt otimizado**: Configurações para usar menos memória
5. **Pacotes removidos**: Snapd, LXD, e outros não essenciais removidos

## Solução de problemas

### 1. Erro de sincronização de pastas
```bash
# Instalar plugin rsync do Vagrant
vagrant plugin install vagrant-rsync-back

# Forçar sincronização
vagrant rsync-auto
```

### 2. Portas em uso
```bash
# Verificar portas em uso
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Parar serviços locais que usam as portas
sudo systemctl stop apache2 nginx
```

### 3. Certificado HTTPS inválido
- O certificado é autoassinado (para desenvolvimento)
- No Chrome: clique em "Avançado" → "Continuar para localhost (não seguro)"
- No Firefox: clique em "Avançado" → "Aceitar o risco e continuar"

### 4. Memória insuficiente
Ajuste no `Vagrantfile`:
```ruby
vb.memory = 4096  # Reduz para 4GB
vb.cpus = 1       # Reduz para 1 CPU
```

## Integração com CI/CD

O ambiente Vagrant pode ser integrado em pipelines de CI:

```yaml
# Exemplo GitHub Actions
jobs:
  vagrant-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Vagrant
        run: |
          sudo apt-get update
          sudo apt-get install -y vagrant virtualbox
      - name: Run Vagrant
        run: |
          cd vagrant-test
          vagrant up --provider=virtualbox --no-parallel
          vagrant ssh -c "docker compose exec web python manage.py test"
      - name: Cleanup
        run: |
          cd vagrant-test
          vagrant destroy -f
```

## Próximos passos

1. **Testar antes do deploy OCI**: Use este ambiente para validar mudanças
2. **Desenvolvimento local**: Ambiente consistente para todos os desenvolvedores
3. **CI/CD**: Integrar em pipelines de teste automatizado
4. **Multi-ambiente**: Criar VMs para hmg/prd similares ao Terraform

## Licença

Este ambiente de teste faz parte do projeto "pos-uncisal-projeto-aplicado".
Use para testes e desenvolvimento local.


## Integração com Makefile (automática)

O projeto principal inclui um Makefile modular que integra todos os comandos do Vagrant:

```bash
# No diretório raiz do projeto
make vagrant-up          # Inicia a VM (com provisionamento)
make vagrant-up-clean    # Destrói e recria a VM (limpo)
make vagrant-halt        # Para a VM
make vagrant-suspend     # Suspende a VM
make vagrant-resume      # Retoma a VM suspensa
make vagrant-destroy     # Destrói a VM
make vagrant-status      # Verifica status da VM
make vagrant-ssh         # SSH para dentro da VM
make vagrant-access      # Mostra URLs de acesso automático
make vagrant-logs        # Mostra logs do provisionamento
make vagrant-docker-logs # Logs dos containers Docker na VM
make vagrant-docker-test # Roda testes Django dentro dos containers na VM
make vagrant-clean       # Limpa arquivos temporários do Vagrant
make vagrant-check       # Verifica pré-requisitos do Vagrant
```

### Fluxo de trabalho recomendado:

```bash
# 1. Teste rápido (5-10 minutos)
make vagrant-up          # Inicia a VM
make vagrant-access      # Mostra URLs para acesso
make vagrant-docker-test # Roda testes automatizados
make vagrant-halt        # Para a VM quando terminar

# 2. Teste completo (reproduz ambiente OCI)
make vagrant-up-clean    # Ambiente limpo
make vagrant-ssh         # Acessar e verificar configurações
make vagrant-logs        # Verificar logs do cloud-init equivalente
make vagrant-destroy     # Remover quando terminar

# 3. Desenvolvimento contínuo
make vagrant-suspend     # Suspender quando não estiver usando
make vagrant-resume      # Retomar quando precisar
```

### Benefícios da integração com Makefile:

- **Unificação de comandos**: Mesma interface para todos os ambientes (local, Docker, Vagrant, OCI)
- **Automatização**: Fluxos de teste multi-ambiente com `make test-matrix`
- **Consistência**: Comandos semelhantes para operações equivalentes
- **Documentação integrada**: `make help` mostra todos os comandos disponíveis

Para lista completa de comandos: `make help` ou consulte `make/README.md`.