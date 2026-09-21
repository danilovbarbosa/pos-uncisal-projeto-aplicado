# Backend local com workspace (hmg)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
