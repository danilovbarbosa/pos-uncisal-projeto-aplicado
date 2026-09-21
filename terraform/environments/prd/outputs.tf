output "instance_public_ip" {
  description = "IP público da instância (onde o Nginx estará acessível)."
  value       = module.compute.public_ip
}

output "ssh_command" {
  description = "Comando SSH para acessar a instância."
  value       = "ssh ubuntu@${module.compute.public_ip}"
}

output "url_http" {
  description = "URL HTTP (redireciona para HTTPS)."
  value       = "http://${module.compute.public_ip}/"
}

output "url_https" {
  description = "URL HTTPS (certificado autoassinado)."
  value       = "https://${module.compute.public_ip}/"
}

output "deploy_status" {
  description = "Status do deploy."
  value       = "O stack Django+Nginx está sendo instalado automaticamente via cloud-init. Acompanhe os logs com: ssh ubuntu@${module.compute.public_ip} 'tail -f /var/log/cloud-init-output.log'"
}
