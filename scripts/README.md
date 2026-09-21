# Scripts do Projeto

Esta pasta centraliza todos os scripts utilitários do projeto **pos-uncisal-projeto-aplicado**.

## 📁 Estrutura

```
scripts/
├── install-gitleaks.sh    # Instalação do gitleaks para verificação de segredos
├── README.md              # Esta documentação
└── (outros scripts futuros)
```

## 📋 Scripts Disponíveis

### **`install-gitleaks.sh`**
Instala o **[gitleaks](https://github.com/gitleaks/gitleaks)** para detecção de segredos no código.

**Uso:**
```bash
./scripts/install-gitleaks.sh
```

**O que faz:**
1. Detecta a arquitetura do sistema (x86_64 ou arm64)
2. Baixa a versão mais recente do gitleaks
3. Instala em `~/bin/gitleaks`
4. Configura o PATH no `.bashrc`
5. Verifica a instalação

**Requisitos:**
- `wget` ou `curl` para download
- Permissões de escrita em `~/bin`

**Integração:**
- Hooks Git (`pre-commit` e `pre-push`) usam automaticamente
- Comando `make install-gitleaks` disponível

## 🔗 Como Executar

Todos os scripts devem ter permissão de execução:

```bash
# Dar permissão de execução
chmod +x scripts/*.sh

# Executar script
./scripts/nome-do-script.sh
```

## 🛠️ Adicionando Novos Scripts

### **Diretrizes:**
1. **Nomeação**: Use `.sh` para scripts bash, `.py` para Python
2. **Documentação**: Adicione entrada nesta README
3. **Portabilidade**: Evite dependências específicas do sistema
4. **Segurança**: Valide entradas e trate erros
5. **Makefile**: Adicione comando correspondente se aplicável

### **Template para novos scripts:**
```bash
#!/bin/bash
# Script: nome-do-script.sh
# Descrição: Breve descrição do que o script faz
# Uso: ./scripts/nome-do-script.sh [parâmetros]

set -e  # Saída em caso de erro

# Configurações
SCRIPT_NAME=$(basename "$0")

# Funções de utilidade
log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERRO] $*" >&2
}

# Validação
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $SCRIPT_NAME [opções]"
    echo ""
    echo "Opções:"
    echo "  -h, --help    Mostra esta ajuda"
    echo "  -v, --verbose Modo verboso"
    exit 0
fi

# Lógica principal
log_info "Iniciando $SCRIPT_NAME..."

# ... código do script ...

log_info "Concluído com sucesso!"
```

## 📚 Scripts Relacionados em Outras Pastas

### **`vagrant-test/scripts/`**
- `security_hardening.sh` - Hardening de segurança para VM Vagrant
- `deploy_app.sh` - Deploy da aplicação Django+Nginx
- `resource_optimization.sh` - Otimizações para recursos limitados

### **`nginx/`**
- `generate-certs.sh` - Geração de certificados TLS autoassinados

### **`docker/`**
- `entrypoint.sh` - Script de inicialização do container Django

### **`terraform/modules/cloud-init/`**
- `cloud-init.yml.tftpl` - Template cloud-init para provisionamento OCI

## 🔄 Integração com Makefile

Cada script pode ter um comando correspondente no Makefile:

```makefile
# Em make/security.mk
install-gitleaks:
    @echo "📥 Instalando gitleaks..."
    @./scripts/install-gitleaks.sh
```

**Vantagens:**
- Interface unificada via `make`
- Documentação automática em `make help`
- Verificação de pré-requisitos
- Tratamento de erros consistente

## 🧪 Testando Scripts

### **Teste básico:**
```bash
# Verificar sintaxe
bash -n scripts/nome-do-script.sh

# Executar em modo de teste (se suportado)
./scripts/nome-do-script.sh --dry-run

# Verificar dependências
./scripts/nome-do-script.sh --check-deps
```

### **Teste no Makefile:**
```bash
# Se houver comando Makefile correspondente
make nome-do-script
```

## 🆘 Solução de Problemas

### **"Permissão negada"**
```bash
chmod +x scripts/nome-do-script.sh
```

### **"Comando não encontrado"**
```bash
# Verificar se o script existe
ls -la scripts/nome-do-script.sh

# Executar do diretório correto
cd /home/sn-387130/Workspace/pos/pos-uncisal-projeto-aplicado
./scripts/nome-do-script.sh
```

### **Erros no script**
```bash
# Executar com debug
bash -x scripts/nome-do-script.sh

# Verificar variáveis de ambiente
env | grep VARIAVEL
```

## 📈 Próximos Scripts Sugeridos

1. **`setup-dev-environment.sh`** - Configuração completa do ambiente de desenvolvimento
2. **`security-audit.sh`** - Auditoria de segurança automatizada
3. **`backup-database.sh`** - Backup do banco de dados SQLite
4. **`deploy-production.sh`** - Script de deploy para produção
5. **`monitoring-setup.sh`** - Configuração de monitoramento

## 🔗 Links Úteis

- [Documentação de Segurança](../docs/SECURITY-HOOKS.md) - Hooks Git e gitleaks
- [Makefile Modular](../make/README.md) - Comandos Makefile
- [Projeto Principal](../README.md) - Visão geral completa