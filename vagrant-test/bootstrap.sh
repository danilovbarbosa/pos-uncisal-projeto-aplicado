#!/bin/bash
# Bootstrap script para ambiente Vagrant de teste

set -e

echo "==========================================="
echo "BOOTSTRAP DO AMBIENTE VAGRANT (1 vCPU, 2GB RAM)"
echo "==========================================="

# Verificar pré-requisitos
echo "Verificando pré-requisitos..."

if ! command -v vagrant &> /dev/null; then
    echo "ERRO: Vagrant não está instalado."
    echo "Instale com:"
    echo "  Ubuntu/Debian: sudo apt install vagrant virtualbox"
    echo "  macOS: brew install --cask vagrant virtualbox"
    exit 1
fi

if ! command -v VBoxManage &> /dev/null; then
    echo "ERRO: VirtualBox não está instalado."
    echo "Baixe em: https://www.virtualbox.org/wiki/Downloads"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "ERRO: Git não está instalado."
    echo "Instale com: sudo apt install git"
    exit 1
fi

# Verificar se estamos no diretório correto
if [ ! -f "Vagrantfile" ]; then
    echo "ERRO: Execute este script do diretório vagrant-test/"
    echo "  cd vagrant-test"
    echo "  ./bootstrap.sh"
    exit 1
fi

echo "Pre-requisitos verificados: ✓"

# Opções
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_MODE=true
            shift
            ;;
        --skip-provision)
            SKIP_PROVISION=true
            shift
            ;;
        --help)
            echo "Uso: ./bootstrap.sh [OPÇÕES]"
            echo ""
            echo "Opções:"
            echo "  --clean         Destruir VM existente antes de criar"
            echo "  --skip-provision  Criar VM sem executar provisionamento"
            echo "  --help          Mostrar esta ajuda"
            echo ""
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            echo "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

# Limpar VM existente se solicitado
if [ "$CLEAN_MODE" = true ]; then
    echo ""
    echo "Limpando VM existente..."
    vagrant destroy -f 2>/dev/null || true
    echo "Limpeza concluída."
fi

# Iniciar VM
echo ""
echo "Iniciando VM Vagrant..."

if [ "$SKIP_PROVISION" = true ]; then
    echo "Modo: Criar VM sem provisionamento"
    vagrant up --no-provision
else
    echo "Modo: Criar VM com provisionamento completo"
    vagrant up
fi

# Verificar se a VM está rodando
if vagrant status | grep -q "running"; then
    echo ""
    echo "==========================================="
    echo "VM VAGRANT INICIADA COM SUCESSO!"
    echo "==========================================="
    
    # Obter IP da VM
    echo ""
    echo "Obtendo informações de acesso..."
    
    VM_IP=$(vagrant ssh -c "ip addr show eth1 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null || true)
    
    if [ -z "$VM_IP" ]; then
        VM_IP=$(vagrant ssh -c "hostname -I | awk '{print \$1}'" 2>/dev/null || true)
    fi
    
    if [ -n "$VM_IP" ]; then
        echo ""
        echo "Acesse a aplicação em:"
        echo "  HTTP:  http://${VM_IP}/"
        echo "  HTTPS: https://${VM_IP}/"
        echo ""
        echo "Credenciais de teste:"
        echo "  Usuário: aluno"
        echo "  Senha: SenhaForte2025!"
        echo ""
        echo "Comandos úteis:"
        echo "  vagrant ssh          # Acessar a VM"
        echo "  vagrant provision    # Reexecutar provisionamento"
        echo "  vagrant halt         # Parar a VM"
        echo "  vagrant destroy -f   # Destruir a VM"
    fi
    
    echo ""
    echo "Para verificar o deploy:"
    echo "  vagrant ssh -c 'docker compose ps'"
    
    echo ""
    echo "Para rodar os testes:"
    echo "  vagrant ssh -c 'docker compose exec web python manage.py test'"
    
    echo ""
    echo "Logs de provisionamento disponíveis em:"
    echo "  cat .vagrant/provisioners/shell/*.log"
    
else
    echo ""
    echo "ERRO: Falha ao iniciar a VM."
    echo "Verifique os logs com:"
    echo "  vagrant up --debug"
    exit 1
fi

echo ""
echo "==========================================="
echo "BOOTSTRAP CONCLUÍDO"
echo "==========================================="