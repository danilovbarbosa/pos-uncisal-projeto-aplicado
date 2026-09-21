# =====================================================================
# Módulo de rede
# =====================================================================
module "network" {
  source = "../../modules/network"

  compartment_ocid        = var.compartment_ocid
  project_name            = var.project_name
  vcn_cidr                = var.vcn_cidr
  vcn_dns_label           = "posvcnhmg"
  public_subnet_cidr      = var.public_subnet_cidr
  public_subnet_dns_label = "publichmg"
}

# =====================================================================
# Módulo cloud-init (gera o user_data)
# =====================================================================
module "cloud_init" {
  source = "../../modules/cloud-init"

  git_repo_url = var.git_repo_url
  git_branch   = var.git_branch
  project_name = var.project_name
}

# =====================================================================
# Módulo de compute (instância)
# =====================================================================
module "compute" {
  source = "../../modules/compute"

  compartment_ocid    = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_id           = module.network.public_subnet_id
  project_name        = var.project_name
  ssh_public_key      = var.ssh_public_key
  instance_cpus       = var.instance_cpus
  instance_memory_gb  = var.instance_memory_gb
  boot_volume_size_gb = var.boot_volume_size_gb
  user_data_content   = module.cloud_init.user_data_base64
  hostname_label      = var.project_name
}
