# Documentação Integrada do Projeto

Este documento fornece uma visão geral das integrações e fluxos de trabalho do projeto **pos-uncisal-projeto-aplicado**.

## Visão Geral do Ecossistema

```
┌─────────────────────────────────────────────────────────────┐
│                    PROJETO DJANGO + OWASP                   │
│                                                             │
│  ┌─────────┐    ┌──────────┐    ┌────────────────────┐    │
│  │  Dev    │◄──►│  Docker  │◄──►│    Vagrant Test    │    │
│  │  Local  │    │ + Nginx  │    │ (OCI Emulation)    │    │
│  └─────────┘    │  HTTPS   │    └────────────────────┘    │
│                 └──────────┘               │               │
│                       │                    │               │
│                       │                    ▼               │
│                       │         ┌────────────────────┐    │
│                       │         │   Oracle Cloud     │    │
│                       │         │    (OCI Always     │    │
│                       │         │      Free Tier)    │    │
│                       ▼         └────────────────────┘    │
│              ┌─────────────────┐               │           │
│              │   Makefile      │◄──────────────┘           │
│              │   Modular       │                           │
│              │ (100+ comandos) │                           │
│              └─────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

## Fluxos de Trabalho Principais

### 1. **Desenvolvimento Local** (Rápido)
```
make setup      → Cria ambiente virtual
make run        → Inicia servidor Django
make test       → Roda testes unitários
make check      → Verifica configurações de segurança
```

### 2. **Testes em Containers** (Docker)
```
make up-d       → Sobe stack Docker + Nginx HTTPS
make docker-test → Testes em containers
make logs       → Monitora logs da aplicação
make down       → Para os containers
```

### 3. **Testes Locais Completos** (Vagrant)
```
make vagrant-up     → Inicia VM com 1 vCPU/2GB RAM
make vagrant-access → Mostra URLs de acesso
make vagrant-docker-test → Testes dentro da VM
make vagrant-halt   → Para a VM
```

### 4. **Deploy na Nuvem** (OCI Always Free)
```
make terraform-hmg-plan  → Verifica plano de homologação
make terraform-hmg-apply → Deploy na OCI (hmg)
make terraform-prd-apply → Deploy na OCI (prd)
make terraform-*-ssh     → SSH para instância
make terraform-*-test    → Testes no ambiente cloud
```

## Testes Multi-Ambiente (Matriz)

O projeto suporta testes em todos os ambientes de forma automatizada:

```bash
# Executa testes em todos os ambientes
make test-matrix

# Resultado:
# ✅ Local (virtualenv)
# ✅ Docker (containers)
# ✅ Vagrant (VM local)
# ✅ OCI Homologação (cloud)
# ✅ OCI Produção (cloud) - opcional
```

## Documentação Especializada

### **Referência Principal**
- **`README.md`** - Visão geral completa do projeto
- **`DOCUMENTACAO-INTEGRADA.md`** - Este documento (visão das integrações)

### **Componentes Específicos**
- **`make/README.md`** - Estrutura modular do Makefile (100+ comandos)
- **`vagrant-test/README.md`** - Ambiente de testes local (1 vCPU/2GB RAM)
- **`terraform/README.md`** - Deploy na Oracle Cloud (Always Free)

### **Arquivos de Configuração**
- **`.env.example`** / **`.env.docker.example`** - Templates de variáveis
- **`docker-compose.yml`** - Stack Docker + Nginx
- **`Vagrantfile`** - Configuração da VM de testes
- **`terraform/environments/*`** - Configurações hmg/prd

## Boas Práticas Implementadas

### **1. Segurança (OWASP Top 10:2025)**
- ✅ **A01**: Broken Access Control (controle de acesso)
- ✅ **A02**: Security Misconfiguration (configuração segura)
- ✅ **A04**: Cryptographic Failures (criptografia adequada)
- ✅ **A05**: Security Logging & Monitoring (logging)
- ✅ **A07**: Identification & Authentication Failures (autenticação)

### **2. DevOps e Automação**
- **Makefile modular**: 7 módulos `.mk`, 100+ comandos
- **Testes multi-ambiente**: local, Docker, Vagrant, OCI
- **IaC completa**: Terraform modular com workspaces
- **Ambientes isolados**: hmg/prd com configurações separadas

### **3. Otimização de Recursos**
- **Vagrant**: 1 vCPU, 2GB RAM, 10GB disco (máquinas modestas)
- **OCI**: VM.Standard.A1.Flex (2 OCPUs, 8GB RAM - Always Free)
- **Docker**: Limites de CPU/memória para containers
- **Swap**: Configurado automaticamente em ambientes limitados

## Integrações e Dependências

### **Arquitetura Docker**
```yaml
web (Django + Gunicorn) ←→ Nginx (HTTPS) ←→ Usuário
       ↑                                     ↑
       └── Banco SQLite                     │
                                            ↓
                                 Certificados TLS
```

### **Provisionamento OCI**
```
Terraform → VCN + Subnet + Security List → Instância A1
                ↓
           Cloud-init → Docker + App + HTTPS
```

### **Hardening de Segurança**
```
Ubuntu → Updates + UFW + fail2ban → SSH hardening
             ↓
        Configurações idênticas (Vagrant ↔ OCI)
```

## Solução de Problemas Comuns

### **Docker**
```bash
# Portas em uso
sudo lsof -i :80 -i :443

# Limpeza de containers
docker system prune -a
```

### **Vagrant**
```bash
# Erro de sincronização
vagrant plugin install vagrant-rsync-back

# Memória insuficiente
# Ajuste no Vagrantfile: vb.memory = 2048
```

### **Terraform OCI**
```bash
# "Out of capacity" para A1
# Mude região: us-ashburn-1, ap-sydney-1, etc.

# Erro de autenticação
# Verifique ~/.oci/config e permissões da chave
```

### **Certificados HTTPS**
```bash
# Gerar novos certificados
make certs

# Chrome: "Avançado" → "Continuar"
# Firefox: "Avançado" → "Aceitar o risco"
```

## Próximos Passos e Melhorias

### **Curto Prazo**
1. **Monitoramento**: Adicionar health checks e métricas
2. **Backup**: Scripts automáticos para banco de dados
3. **CI/CD**: Integração com GitHub Actions/GitLab CI

### **Médio Prazo**
1. **Banco de dados**: Migrar para PostgreSQL em produção
2. **Load balancing**: Múltiplas instâncias com balanceador
3. **CDN**: Cache estático com CloudFlare/Akamai

### **Longo Prazo**
1. **Kubernetes**: Orquestração de containers
2. **Service Mesh**: Istio/Linkerd para microserviços
3. **Observability**: Jaeger, Prometheus, Grafana

## Conclusão

O projeto implementa uma **pipeline DevOps completa**:
- **Desenvolvimento** → **Testes** → **Deploy** → **Monitoramento**
- **Segurança por design** com OWASP Top 10:2025
- **Recursos gratuitos** (OCI Always Free, Vagrant local)
- **Automação extensiva** com Makefile modular

Para começar: `make help` ou consulte os READMEs específicos de cada componente.