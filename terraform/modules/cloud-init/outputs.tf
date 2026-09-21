output "user_data_base64" {
  description = "Conteúdo do cloud-init codificado em base64."
  value       = base64encode(local.cloud_init_yml)
}

output "cloud_init_raw" {
  description = "Conteúdo raw do cloud-init (sem codificação)."
  value       = local.cloud_init_yml
  sensitive   = true
}
