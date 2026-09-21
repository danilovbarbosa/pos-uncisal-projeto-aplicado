# Inputs do módulo cloud-init
variable "git_repo_url" {
  description = "URL do repositório Git do projeto."
  type        = string
}

variable "git_branch" {
  description = "Branch do repositório a ser clonado."
  type        = string
  default     = "main"
}

variable "project_name" {
  description = "Prefixo usado para nomear os recursos."
  type        = string
  default     = "pos-uncisal"
}
