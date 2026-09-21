# =====================================================================
# Data source: imagem mais recente do Ubuntu 24.04 LTS (ARM64)
# =====================================================================
data "oci_core_images" "ubuntu_24_04_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"

  filter {
    name   = "display_name"
    values = ["Canonical-Ubuntu-24.04-Minimal-*"]
  }

  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }
}

# =====================================================================
# Instância Ampere A1 (Always Free)
# =====================================================================
resource "oci_core_instance" "app_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.project_name}-instance"
  shape               = "VM.Standard.A1.Flex"

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
  }

  shape_config {
    ocpus         = var.instance_cpus
    memory_in_gbs = var.instance_memory_gb
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_24_04_arm.images[0].id

    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = var.user_data_content
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    hostname_label   = var.hostname_label
  }

  preserve_boot_volume = false
}
