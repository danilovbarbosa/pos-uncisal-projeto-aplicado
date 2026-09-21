# Este módulo não cria recursos, apenas gera o user_data.
# A saída é o conteúdo codificado em base64.

locals {
  cloud_init_yml = templatefile("${path.module}/cloud-init.yml.tftpl", {
    git_repo_url = var.git_repo_url
    git_branch   = var.git_branch
    project_name = var.project_name
  })
}
