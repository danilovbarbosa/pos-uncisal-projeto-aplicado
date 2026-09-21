# =====================================================================
# Variáveis de autenticação OCI (obrigatórias)
# =====================================================================
variable "tenancy_ocid" {
  description = "OCID da tenancy (sua conta OCI)."
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCID do usuário OCI que fará a API request."
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint da chave pública configurada para este usuário."
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Caminho para a chave privada (PEM) do usuário."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Região OCI (ex: sa-saopaulo-1, us-ashburn-1)."
  type        = string
  default     = "sa-saopaulo-1"
}

variable "compartment_ocid" {
  description = "OCID do compartment onde os recursos serão criados."
  type        = string
  sensitive   = true
}

# =====================================================================
# Configuração da instância e rede
# =====================================================================
variable "availability_domain" {
  description = "Availability Domain (AD) onde a instância será criada. Ex: 'Uocm:SA-SAOPAULO-1-AD-1'."
  type        = string
  default     = "Uocm:SA-SAOPAULO-1-AD-1"
}

variable "project_name" {
  description = "Prefixo usado para nomear os recursos."
  type        = string
  default     = "pos-uncisal-prd"
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso à instância."
  type        = string
  sensitive   = true
}

# =====================================================================
# Configuração do Always Free tier (Ampere A1)
# =====================================================================
variable "instance_cpus" {
  description = "Número de OCPUs para a instância (free tier: máximo 2 OCPU por instância A1)."
  type        = number
  default     = 2
  validation {
    condition     = var.instance_cpus >= 1 && var.instance_cpus <= 2
    error_message = "A free tier da OCI permite no máximo 2 OCPUs per instância A1."
  }
}

variable "instance_memory_gb" {
  description = "Memória da instância em GB (free tier: máximo 12 GB total)."
  type        = number
  default     = 8
  validation {
    condition     = var.instance_memory_gb >= 1 && var.instance_memory_gb <= 12
    error_message = "A free tier da OCI permite no máximo 12 GB de RAM per instância A1."
  }
}

variable "boot_volume_size_gb" {
  description = "Tamanho do boot volume em GB (free tier: 200 GB incluídos)."
  type        = number
  default     = 50
}

variable "git_repo_url" {
  description = "URL do repositório Git do projeto (pode ser fork/local)."
  type        = string
  default     = "https://github.com/seu-usuario/pos-uncisal-projeto-aplicado.git"
}

variable "git_branch" {
  description = "Branch do repositório a ser clonado."
  type        = string
  default     = "main"
}

# =====================================================================
# Configurações de rede (opcional)
# =====================================================================
variable "vcn_cidr" {
  description = "CIDR block da VCN."
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública."
  type        = string
  default     = "10.10.1.0/24"
}
