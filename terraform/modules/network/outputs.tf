output "vcn_id" {
  description = "ID da VCN criada."
  value       = oci_core_virtual_network.vcn.id
}

output "public_subnet_id" {
  description = "ID da subnet pública."
  value       = oci_core_subnet.public_subnet.id
}

output "security_list_id" {
  description = "ID da security list pública."
  value       = oci_core_security_list.public_security_list.id
}

output "public_route_table_id" {
  description = "ID da route table pública."
  value       = oci_core_route_table.public_route_table.id
}

output "internet_gateway_id" {
  description = "ID do internet gateway."
  value       = oci_core_internet_gateway.internet_gateway.id
}
