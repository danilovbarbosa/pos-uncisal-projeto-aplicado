# Inputs do módulo network
variable "compartment_ocid" {
  description = "OCID do compartment onde a rede será criada."
  type        = string
}

variable "project_name" {
  description = "Prefixo usado para nomear os recursos."
  type        = string
  default     = "pos-uncisal"
}

variable "vcn_cidr" {
  description = "CIDR block da VCN."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_dns_label" {
  description = "DNS label da VCN."
  type        = string
  default     = "posvcn"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_dns_label" {
  description = "DNS label da subnet pública."
  type        = string
  default     = "public"
}
