# Terraform para Oracle Cloud (OCI) – Estrutura Modular com Workspaces

Terraform modular para provisionar uma instância **Ampere A1 (ARM64)** no **Always Free tier** da Oracle Cloud, rodando o stack Docker (Django + Gunicorn + Nginx HTTPS).

## Estrutura do Projeto

```
terraform/
├── modules/                     # Módulos reutilizáveis
│   ├── network/                 # VCN, subnet, security list, internet gateway
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── compute/                 # Instância A1, data source da imagem Ubuntu ARM
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── cloud-init/              # Geração do user_data (cloud-init)
│       ├── main.tf
│       ├── outputs.tf
│       ├── variables.tf
│       └── cloud-init.yml.tftpl
├── environments/                # Ambientes separados
│   ├── hmg/                     # Homologação
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── prd/                     # Produção
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── provider.tf                  # Provider OCI (comum)
├── versions.tf                  # Versões do Terraform e providers (comum)
└── README.md                    # Este arquivo
```

## Recursos provisionados

Cada ambiente (hmg/prd) provisiona:

- **VCN** com uma subnet pública (CIDR configurável)
- **Internet Gateway** + Route Table
- **Security List** abrindo portas 22 (SSH), 80 (HTTP) e 443 (HTTPS)
- **Instância** `VM.Standard.A1.Flex` (Ampere A1) com Ubuntu 24.04 LTS ARM
- **Cloud‑init** que:
  - Instala Docker e Docker Compose
  - Clona o repositório Git configurado
  - Gera um certificado TLS autoassinado
  - Cria o arquivo `.env.docker` com uma `SECRET_KEY` gerada automaticamente
  - Sobe o stack com `docker compose up --build -d`

Ao final, a aplicação estará acessível via **HTTPS** com um certificado autoassinado (aceite o aviso no navegador em dev).

## Pré‑requisitos

1. **Conta OCI** com Always Free habilitado (é necessário cartão de crédito, mas o free tier não cobra).
2. **Credenciais OCI** configuradas:
   - OCID da tenancy, usuário, compartment
   - Chave API (pública/privada) com fingerprint
   - Ver [Documentação OCI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
3. **Terraform** instalado (>= 1.5.0)
4. **Git** (para o repositório do projeto)

## Como usar (por ambiente)

### 1. Escolha o ambiente

- **Homologação (hmg)**: ambiente de testes, com CIDRs `10.0.0.0/16` (VCN) e `10.0.1.0/24` (subnet).
- **Produção (prd)**: ambiente de produção, com CIDRs `10.10.0.0/16` (VCN) e `10.10.1.0/24` (subnet).

### 2. Preparar a chave SSH

```bash
ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo" -f ~/.ssh/oci_pos_uncisal
```

A chave pública (`~/.ssh/oci_pos_uncisal.pub`) será usada na variável `ssh_public_key`.

### 3. Configurar as variáveis

Vá para o diretório do ambiente escolhido e copie o modelo:

```bash
cd terraform/environments/hmg   # ou prd
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` com:
- Credenciais OCI (tenancy_ocid, user_ocid, fingerprint, private_key_path, compartment_ocid)
- Chave pública SSH
- URL do repositório Git (se fez fork)
- Outros parâmetros (instance_cpus, memory, etc.)

### 4. Inicializar e aplicar

```bash
# No diretório do ambiente (hmg ou prd)
terraform init
terraform plan
terraform apply -auto-approve
```

> **Nota**: Cada ambiente tem seu próprio estado (`terraform.tfstate`) isolado.

### 5. Acessar a aplicação

Após o apply, o Terraform exibirá os outputs:

```
instance_public_ip = "150.136.xxx.xxx"
ssh_command        = "ssh ubuntu@150.136.xxx.xxx"
url_http           = "http://150.136.xxx.xxx/"
url_https          = "https://150.136.xxx.xxx/"
```

O cloud‑init pode levar **3‑5 minutos** para concluir a instalação. Acompanhe os logs:

```bash
ssh ubuntu@$(terraform output -raw instance_public_ip) 'tail -f /var/log/cloud-init-output.log'
```

Quando pronto, acesse **https://SEU_IP/** no navegador (ignorando o aviso do certificado autoassinado).

## Limites do Always Free (2026)

- **CPU**: 2 OCPUs máximos por instância A1
- **RAM**: 12 GB máximos por instância A1
- **Armazenamento**: 200 GB de block volume
- **IPs públicos**: 2 per tenancy
- **Tráfego de saída**: 10 TB/mês

Os valores padrão usam **2 OCPUs** e **8 GB de RAM**, dentro dos limites gratuitos.

## Comandos úteis

```bash
# No diretório do ambiente
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
terraform destroy -var-file="terraform.tfvars"

# Verificar estado
terraform state list
terraform output

# Acompanhar logs da instância
ssh ubuntu@$(terraform output -raw instance_public_ip) 'docker compose logs -f'

# Rodar testes dentro do container
ssh ubuntu@$(terraform output -raw instance_public_ip) 'cd /opt/pos-uncisal-hmg/projeto && docker compose exec web python manage.py test'
```

## Solução de problemas

- **“Out of capacity”**: a região não tem capacidade para A1. Troque a região (ex: `us-ashburn-1`) ou tente outro Availability Domain.
- **Erro de autenticação OCI**: verifique se as credenciais no `terraform.tfvars` estão corretas e se a chave privada tem permissões adequadas (`chmod 600`).
- **Cloud‑init falhou**: verifique os logs em `/var/log/cloud-init-output.log` na instância.

## Personalização

### Módulos

Cada módulo (`network`, `compute`, `cloud-init`) é independente e pode ser reutilizado em outros projetos. Os inputs estão em `variables.tf` e as saídas em `outputs.tf`.

### Adicionar novo ambiente

Para criar um novo ambiente (ex: `dev`):

1. Copie a pasta `hmg` para `dev`:
   ```bash
   cp -r terraform/environments/hmg terraform/environments/dev
   ```
2. Ajuste os valores em `dev/variables.tf` e `dev/terraform.tfvars.example`.
3. Use `terraform init` dentro de `dev/` para inicializar.

### Alterar a shape da instância

Edite `modules/compute/variables.tf` e `modules/compute/main.tf` para suportar outras shapes (ex: `VM.Standard.E2.1.Micro`). Lembre‑se dos limites do Always Free.

## Observações

- O backend está configurado como `local` (estado salvo no diretório do ambiente). Para times, considere usar um backend remoto (ex: OCI Object Storage).
- Os certificados TLS são autoassinados e válidos apenas para desenvolvimento. Em produção, substitua por certificados de uma CA confiável (Let's Encrypt).


## Integração com Makefile (automática)

O projeto principal inclui um Makefile modular que integra todos os comandos do Terraform:

```bash
# No diretório raiz do projeto
make terraform-<ambiente>-plan    # ex: make terraform-hmg-plan
make terraform-<ambiente>-apply   # ex: make terraform-prd-apply
make terraform-<ambiente>-destroy # ex: make terraform-prd-destroy
make terraform-<ambiente>-output  # ex: make terraform-hmg-output
make terraform-<ambiente>-ssh     # ex: make terraform-prd-ssh
```

### Comandos disponíveis via Makefile:
- `terraform-hmg-plan` / `terraform-prd-plan` - Plano de execução
- `terraform-hmg-apply` / `terraform-prd-apply` - Aplicar configuração
- `terraform-hmg-destroy` / `terraform-prd-destroy` - Destruir recursos
- `terraform-hmg-output` / `terraform-prd-output` - Ver outputs
- `terraform-hmg-ssh` / `terraform-prd-ssh` - SSH para a instância
- `terraform-hmg-logs` / `terraform-prd-logs` - Logs da aplicação
- `terraform-hmg-test` / `terraform-prd-test` - Rodar testes Django na VM

### Exemplo de fluxo completo:

```bash
# Desenvolvimento local → Testes Vagrant → Deploy OCI
make setup               # Ambiente local
make test-matrix        # Testes em todos ambientes
make terraform-hmg-plan # Verificar plano OCI
make terraform-hmg-apply # Deploy em homologação
make terraform-hmg-test  # Rodar testes no ambiente hmg
make terraform-prd-apply # Deploy em produção
```

Para lista completa de comandos: `make help` ou consulte `make/README.md`.