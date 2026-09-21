# Inputs do módulo compute
variable "compartment_ocid" {
  description = "OCID do compartment."
  type        = string
}

variable "availability_domain" {
  description = "Availability Domain (AD) onde a instância será criada."
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a instância será colocada."
  type        = string
}

variable "project_name" {
  description = "Prefixo usado para nomear os recursos."
  type        = string
  default     = "pos-uncisal"
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso à instância."
  type        = string
  sensitive   = true
}

variable "instance_cpus" {
  description = "Número de OCPUs para a instância."
  type        = number
  default     = 2
}

variable "instance_memory_gb" {
  description = "Memória da instância em GB."
  type        = number
  default     = 8
}

variable "boot_volume_size_gb" {
  description = "Tamanho do boot volume em GB."
  type        = number
  default     = 50
}

variable "user_data_content" {
  description = "Conteúdo do cloud-init (já codificado em base64)."
  type        = string
}

variable "hostname_label" {
  description = "Label de hostname para o VNIC."
  type        = string
  default     = "pos-uncisal"
}
