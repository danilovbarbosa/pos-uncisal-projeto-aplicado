# Backend local com workspace (prd)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
