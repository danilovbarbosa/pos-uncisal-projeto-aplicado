# Hooks de Segurança do Git (Gitleaks)

Este documento descreve os hooks de segurança configurados no projeto para prevenir a exposição de segredos no código.

## 📋 Visão Geral

Foram configurados dois hooks do Git para verificação de segredos:

1. **`pre-commit`** - Verifica segredos nos arquivos staged antes do commit
2. **`pre-push`** - Verifica segredos no histórico completo antes do push

Ambos os hooks usam o **[gitleaks](https://github.com/gitleaks/gitleaks)**, uma ferramenta de detecção de segredos em repositórios Git.

## 🚀 Como Funciona

### **Hook Pré-commit**
- **Quando**: Antes de cada `git commit`
- **O que faz**: Verifica apenas os arquivos que estão no stage (`git add`)
- **Resultado**: Bloqueia o commit se encontrar segredos
- **Comando equivalente**: `gitleaks protect --staged`

### **Hook Pré-push**
- **Quando**: Antes de cada `git push`
- **O que faz**: Verifica todo o histórico do repositório
- **Resultado**: Bloqueia o push se encontrar segredos no histórico
- **Comando equivalente**: `gitleaks detect --source .`

## 📁 Arquivos Configurados

```
.git/hooks/
├── pre-commit          # Hook para verificação pré-commit
├── pre-push            # Hook para verificação pré-push
└── (outros hooks de exemplo)
```

```
projeto/
├── install-gitleaks.sh # Script de instalação do gitleaks
├── make/security.mk    # Comandos Makefile para segurança
└── docs/SECURITY-HOOKS.md # Esta documentação
```

## 🔧 Instalação

### **1. Instalar gitleaks**
```bash
# Usando o script de instalação
./scripts/install-gitleaks.sh

# Ou manualmente:
mkdir -p ~/bin
cd /tmp
wget https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_linux_x64.tar.gz
tar -xzf gitleaks_linux_x64.tar.gz
mv gitleaks ~/bin/
chmod +x ~/bin/gitleaks
```

### **2. Verificar instalação**
```bash
make check-gitleaks
# Saída esperada: ✅ gitleaks encontrado: /home/usuario/bin/gitleaks
```

### **3. Testar os hooks**
```bash
make gitleaks-test
# Cria um arquivo de teste com segredo falso e verifica se o hook bloqueia
```

## 📝 Comandos Makefile Disponíveis

| Comando | Descrição |
|---------|-----------|
| `make install-gitleaks` | Instala o gitleaks |
| `make check-gitleaks` | Verifica se o gitleaks está instalado |
| `make gitleaks-detect` | Verifica segredos no histórico completo |
| `make gitleaks-protect` | Verifica segredos nos arquivos staged |
| `make gitleaks-test` | Testa os hooks de segurança |
| `make security-check` | Verificação completa de segurança |

## 🔍 Tipos de Segredos Detectados

O gitleaks detecta automaticamente:

- **SECRET_KEY do Django**
- **Chaves privadas** (RSA, EC, DSA, OpenSSH)
- **Tokens de API** (Stripe, GitHub, GitLab, etc.)
- **Credenciais AWS** (access key, secret key)
- **Credenciais OCI** (tenancy_ocid, user_ocid, fingerprint)
- **Senhas** em variáveis de ambiente
- **Tokens de acesso** genéricos
- **E muitos outros padrões**...

## ⚠️ O Que Fazer Se o Hook Bloquear

### **Se o pré-commit bloquear:**
1. **Remova os segredos** dos arquivos commitados
2. **Use arquivos `.env`** (não versionados) para segredos
3. **Mantenha apenas arquivos `.example`** versionados
4. **Verifique** se são falsos positivos

### **Se o pré-push bloquear:**
1. **Verifique o histórico** completo: `make gitleaks-detect`
2. **Identifique os commits** problemáticos
3. **Se o repositório for privado/local**: Use `git filter-repo` para remover segredos
4. **Se segredos foram expostos publicamente**: REVOQUE-OS IMEDIATAMENTE

## 🎯 Boas Práticas

### **✅ O QUE FAZER:**
- Use arquivos `.env` para segredos (adicionados ao `.gitignore`)
- Mantenha arquivos `.env.example` versionados com valores de exemplo
- Execute `make gitleaks-detect` periodicamente
- Configure alertas de segredos no GitHub/GitLab se usar esses serviços

### **❌ O QUE NÃO FAZER:**
- Nunca commit segredos reais
- Não use `git commit --no-verify` para contornar os hooks (exceto emergências)
- Não ignore avisos do gitleaks

## 🔄 Fluxo de Trabalho com Segurança

```bash
# 1. Desenvolvimento normal
make setup
make run

# 2. Antes de commitar
git add arquivos.py
git commit -m "mensagem"  # Hook pré-commit será executado

# 3. Se houver segredos:
#    - O commit será bloqueado
#    - Corrija os arquivos
#    - Faça git add novamente
#    - Tente commit novamente

# 4. Antes de fazer push
git push origin branch  # Hook pré-push será executado

# 5. Se houver segredos no histórico:
#    - O push será bloqueado
#    - Use make gitleaks-detect para identificar
#    - Corrija o histórico se necessário
```

## 🛠️ Personalização

### **Configuração do Gitleaks**
Por padrão, usamos a configuração embutida do gitleaks. Para personalizar:

1. Crie um arquivo `.gitleaks.toml` na raiz do projeto
2. Adicione regras específicas para seu projeto
3. Configure exclusões (allowlist) para falsos positivos

### **Exemplo de .gitleaks.toml:**
```toml
title = "Configuração Personalizada"

[[rules]]
id = "django-secret-key"
description = "SECRET_KEY do Django"
regex = '''SECRET_KEY\s*=\s*['"][^'"]{20,}['"]'''

[allowlist]
paths = [
    ".env.example",
    ".env.docker.example",
    "**/*.tfstate",
    "**/*.tfstate.*",
]
```

## 📊 Verificação Manual

### **Verificar histórico completo:**
```bash
make gitleaks-detect
# ou
gitleaks detect --source . -v
```

### **Verificar apenas staged files:**
```bash
make gitleaks-protect
# ou
gitleaks protect --staged -v
```

### **Testar arquivo específico:**
```bash
gitleaks detect --path arquivo.conf
```

## 🆘 Solução de Problemas

### **Problema: "gitleaks não encontrado"**
```bash
# Solução:
make install-gitleaks
# ou execute o script diretamente:
./scripts/install-gitleaks.sh
# ou adicione ao PATH:
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bashrc
source ~/.bashrc
```

### **Problema: Hook não está executando**
```bash
# Verifique permissões:
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push

# Verifique se hooks estão habilitados:
ls -la .git/hooks/
```

### **Problema: Falsos positivos**
1. Verifique se o segredo é real ou de exemplo
2. Se for de exemplo, considere movê-lo para `.env.example`
3. Para exclusões permanentes, crie `.gitleaks.toml`

## 🔗 Links Úteis

- [gitleaks GitHub](https://github.com/gitleaks/gitleaks) - Repositório oficial
- [Documentação gitleaks](https://gitleaks.io/) - Site oficial
- [OWASP Top 10:2025](https://owasp.org/Top10/2025/) - Referência de segurança
- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) - Documentação oficial

---

**⚠️ Lembre-se:** Segredos expostos em repositórios públicos devem ser considerados **COMPROMETIDOS** e **REVOGADOS IMEDIATAMENTE**.

Os hooks de segurança são sua primeira linha de defesa contra vazamentos de segredos. Mantenha-os ativos e funcioneis em todos os ambientes de desenvolvimento.