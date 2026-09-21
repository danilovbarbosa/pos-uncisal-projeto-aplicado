#!/bin/bash

# Script de instalação do gitleaks para o projeto

echo "📥 Instalando gitleaks para verificação de segredos..."

# Criar diretório bin se não existir
mkdir -p ~/bin

# Verificar arquitetura
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_TYPE="linux_x64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH_TYPE="linux_arm64"
else
    echo "❌ Arquitetura não suportada: $ARCH"
    exit 1
fi

# Baixar e instalar gitleaks
echo "📦 Baixando gitleaks para $ARCH..."
cd /tmp

# Tentar encontrar a versão mais recente
GITLEAKS_URL="https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_${ARCH_TYPE}.tar.gz"

if ! wget -q "$GITLEAKS_URL"; then
    echo "⚠️  Não foi possível baixar a versão mais recente, tentando versão específica..."
    GITLEAKS_URL="https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_${ARCH_TYPE}.tar.gz"
    wget -q "$GITLEAKS_URL"
fi

if [ -f "gitleaks_${ARCH_TYPE}.tar.gz" ]; then
    tar -xzf "gitleaks_${ARCH_TYPE}.tar.gz"
    mv gitleaks ~/bin/
    chmod +x ~/bin/gitleaks
    rm "gitleaks_${ARCH_TYPE}.tar.gz"
elif [ -f "gitleaks_8.18.4_${ARCH_TYPE}.tar.gz" ]; then
    tar -xzf "gitleaks_8.18.4_${ARCH_TYPE}.tar.gz"
    mv gitleaks ~/bin/
    chmod +x ~/bin/gitleaks
    rm "gitleaks_8.18.4_${ARCH_TYPE}.tar.gz"
else
    echo "❌ Não foi possível baixar o gitleaks"
    exit 1
fi

# Verificar instalação
if ~/bin/gitleaks version >/dev/null 2>&1; then
    echo "✅ gitleaks instalado com sucesso!"
    echo "   Versão: $(~/bin/gitleaks version)"
    echo ""
    echo "🔧 Configuração dos hooks do Git:"
    echo "   - pré-commit: Verifica segredos nos arquivos staged"
    echo "   - pré-push: Verifica segredos no histórico completo"
    echo ""
    echo "📝 Para testar a instalação:"
    echo "   ~/bin/gitleaks detect --source ."
    echo ""
    echo "💡 Os hooks já estão configurados em .git/hooks/"
    echo "   Eles serão executados automaticamente em commits e pushes."
else
    echo "❌ Falha na instalação do gitleaks"
    exit 1
fi

# Adicionar ao PATH no .bashrc se não estiver
if ! grep -q "export PATH.*~/bin" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Adicionar ~/bin ao PATH para gitleaks" >> ~/.bashrc
    echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bashrc
    echo "📝 Adicionado ~/bin ao PATH no .bashrc"
fi

echo "🎉 Instalação concluída! Reinicie o terminal ou execute:"
echo "   source ~/.bashrc"