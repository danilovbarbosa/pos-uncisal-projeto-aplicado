# =====================================================================
# Rede (VCN)
# =====================================================================
resource "oci_core_virtual_network" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.project_name}-vcn"
  dns_label      = var.vcn_dns_label
  is_ipv6enabled = false
}

# =====================================================================
# Internet Gateway (para internet pública)
# =====================================================================
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.project_name}-internet-gateway"
  enabled        = true
}

# =====================================================================
# Route Table (roteia tráfego 0.0.0.0/0 → internet gateway)
# =====================================================================
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.project_name}-public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

# =====================================================================
# Subnet pública (para a instância com IP público)
# =====================================================================
resource "oci_core_subnet" "public_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "${var.project_name}-public-subnet"
  dns_label                  = var.public_subnet_dns_label
  prohibit_public_ip_on_vnic = false # permite IP público
  route_table_id             = oci_core_route_table.public_route_table.id

  security_list_ids = [
    oci_core_security_list.public_security_list.id,
  ]
}

# =====================================================================
# Security List (regras de firewall)
# =====================================================================
resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.project_name}-security-list"

  # SSH (porta 22) do mundo todo
  ingress_security_rules {
    description = "SSH do mundo todo"
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP (porta 80) do mundo todo
  ingress_security_rules {
    description = "HTTP do mundo todo"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS (porta 443) do mundo todo
  ingress_security_rules {
    description = "HTTPS do mundo todo"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Docker e serviços internos da VM
  ingress_security_rules {
    description = "Tráfego interno da subnet"
    protocol    = "6"
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 1
      max = 65535
    }
  }

  # Permite todo o egress (saída)
  egress_security_rules {
    description      = "Todo o egress"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
}
