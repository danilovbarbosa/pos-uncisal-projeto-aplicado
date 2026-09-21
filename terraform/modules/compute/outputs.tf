output "instance_id" {
  description = "ID da instância criada."
  value       = oci_core_instance.app_instance.id
}

output "public_ip" {
  description = "IP público da instância."
  value       = oci_core_instance.app_instance.public_ip
}

output "private_ip" {
  description = "IP privado da instância."
  value       = oci_core_instance.app_instance.private_ip
}

output "display_name" {
  description = "Nome de exibição da instância."
  value       = oci_core_instance.app_instance.display_name
}
