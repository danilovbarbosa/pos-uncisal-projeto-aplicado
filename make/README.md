# Estrutura Modular do Makefile (boas práticas)

O Makefile do projeto foi modularizado seguindo as melhores práticas da indústria, com arquivos organizados no diretório `make/` com extensão `.mk`. Esta estrutura é parte do projeto completo **pos-uncisal-projeto-aplicado** que implementa um protótipo web Django com segurança OWASP Top 10:2025, Dockerização com Nginx HTTPS, e infraestrutura como código para Oracle Cloud (Always Free tier).

## Estrutura de Arquivos

```
.
├── Makefile                    # Arquivo principal (includes)
├── make/                       # Módulos Makefile
│   ├── README.md              # Esta documentação
│   ├── common.mk              # Configurações e variáveis compartilhadas
│   ├── help.mk                # Meta-comandos (help)
│   ├── local.mk               # Ambiente local (virtualenv)
│   ├── docker.mk              # Docker + Nginx (HTTPS)
│   ├── vagrant.mk             # Vagrant (testes locais)
│   ├── test.mk                # Testes integrados
│   └── clean.mk               # Limpeza
└── ...                         # Outros diretórios do projeto
```

## Arquivos

### **Makefile** (principal)
- Inclui todos os módulos `.mk`
- Define `.DEFAULT_GOAL := help`
- Ponto de entrada único para todos os comandos

### **make/common.mk**
- Configurações e variáveis compartilhadas
- Definições de diretórios, comandos, etc.
- Funções auxiliares (como `print_help`)

### **make/help.mk**
- Meta-comandos (principalmente `help`)

### **make/local.mk**
- Comandos para ambiente local (virtualenv)
- Desenvolvimento Django local
- Migrações, superusuário, etc.

### **make/docker.mk**
- Comandos para Docker + Nginx HTTPS
- Build, deploy, logs, testes em containers

### **make/vagrant.mk**
- Comandos para ambiente Vagrant de testes
- Controle da VM, provisionamento, acesso

### **make/test.mk**
- Comandos de testes integrados
- Testes multi-ambiente (local, Docker, Vagrant)

### **make/clean.mk**
- Comandos de limpeza
- Remoção de caches, virtualenv, etc.

## Benefícios da Estrutura (boas práticas)

### 1. **Organização**
- Cada arquivo tem responsabilidade clara
- Fácil encontrar comandos relacionados
- Separação lógica por funcionalidade

### 2. **Manutenção**
- Modificações isoladas em arquivos específicos
- Menos conflitos em equipes
- Fácil adicionar novas funcionalidades

### 3. **Reusabilidade**
- Arquivos podem ser copiados/reutilizados em outros projetos
- Configurações compartilhadas centralizadas

### 4. **Legibilidade**
- Arquivos menores e mais focados
- Menos linhas por arquivo (mais fácil de ler)

### 5. **Extensibilidade**
- Fácil adicionar novos módulos (ex: `Makefile.deploy`)
- Inclusão condicional de módulos

## Boas Práticas Implementadas

1. **Separação por funcionalidade**: Cada arquivo `.mk` tem responsabilidade única
2. **Extensão `.mk`**: Identifica claramente como módulos Makefile
3. **Diretório `make/`**: Centraliza todos os módulos
4. **`common.mk`**: Configurações compartilhadas em um lugar
5. **Documentação**: Comentários `##` aparecem no `make help`
6. **`.DEFAULT_GOAL`**: Definido como `help` no Makefile principal
7. **`$(call print_help)`**: Função centralizada para mostrar ajuda

## Como adicionar novos comandos/módulos

### 1. Adicionar novo comando em módulo existente:
```bash
# Exemplo: adicionar comando em make/local.mk
echo -e '\n.PHONY: novo-local\nnovo-local: ## Descrição do comando local\n\t@echo "Executando..."' >> make/local.mk
```

### 2. Criar novo módulo `.mk`:
```bash
# 1. Criar arquivo
cat > make/novo.mk << 'EOF'
# =====================================================================
# make/novo.mk — Novas funcionalidades
# =====================================================================

.PHONY: novo-comando
novo-comando: ## Descrição do novo comando
	@echo "Executando novo comando..."
EOF

# 2. Incluir no Makefile principal
# Editar Makefile e adicionar: include make/novo.mk
```

### 3. Testar:
```bash
make help | grep novo-comando
make novo-comando
```

## Fluxo de execução

```
make <comando>
    ↓
Makefile (inclui todos os módulos)
    ↓
Makefile.config (carrega configurações)
    ↓
Arquivo específico (executa o comando)
```

## Exemplo de uso

```bash
# Ver todos os comandos
make help

# Ambiente local
make setup
make run

# Docker
make up-d
make docker-test

# Vagrant
make vagrant-up
make vagrant-access

# Testes integrados
make test-matrix

# Limpeza
make clean
```

## Dicas

1. **Variáveis**: Definidas em `Makefile.config`, usadas em todos os módulos
2. **Documentação**: Use `##` após `:` para documentação no `make help`
3. **Dependências**: Defina em `Makefile.local` para comandos compostos
4. **Phony targets**: Sempre use `.PHONY:` para targets que não criam arquivos

## Documentação Relacionada

Este Makefile é parte de um ecossistema completo de documentação:

### **Documentação do Projeto**
- **README principal**: Visão geral completa do projeto - [../README.md](../README.md)
- **OWASP Top 10:2025**: Detalhes das mitigações implementadas

### **Ambientes de Teste**
- **Vagrant**: Ambiente local de testes - [../vagrant-test/README.md](../vagrant-test/README.md)
- **Docker + Nginx**: Stack de containers com HTTPS

### **Infraestrutura como Código**
- **Terraform OCI**: Deploy na Oracle Cloud - [../terraform/README.md](../terraform/README.md)
- **Workspaces hmg/prd**: Ambientes separados
- **Módulos**: network, compute, cloud-init

### **Comandos Makefile por Categoria**

| Módulo | Arquivo | Categoria | Exemplos |
|--------|---------|-----------|----------|
| **Local** | `local.mk` | Desenvolvimento | `make setup`, `make run`, `make test` |
| **Docker** | `docker.mk` | Containers | `make up-d`, `make docker-test`, `make logs` |
| **Vagrant** | `vagrant.mk` | Testes locais | `make vagrant-up`, `make vagrant-access` |
| **Testes** | `test.mk` | Qualidade | `make test-matrix`, `make test-all` |
| **Utilidades** | `common.mk` | Configuração | `make secret-key`, `make certs` |
| **Limpeza** | `clean.mk` | Manutenção | `make clean`, `make clean-all` |

## Como Contribuir

1. **Adicionar novos comandos**:
   - Adicione ao módulo `.mk` apropriado
   - Mantenha padrão de nomenclatura: `categoria-alvo`
   - Adicione ajuda em `help.mk`

2. **Criar novo módulo**:
   ```makefile
   # make/novo.mk
   .PHONY: novo-exemplo
   novo-exemplo:
       @echo "Exemplo de comando"
   ```
   ```makefile
   # Makefile (principal)
   include make/novo.mk
   ```

3. **Manter consistência**:
   - Use variáveis definidas em `common.mk`
   - Adicione `.PHONY` para alvos não arquivos
   - Inclua documentação em `help.mk`

Para lista completa de comandos: `make help` no diretório raiz do projeto.