# Create VM in yandex.cloud
resource "yandex_compute_instance" "VPS" {
  platform_id = var.vps_platform_id
  count       = var.vps_count
  name        = "VPS"

  resources {
    cores         = var.vps_cores
    memory        = var.vps_ram
    core_fraction = var.vps_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.vps_boot_disk_size
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = var.vps_nat
  }

  metadata = {
    ssh-keys           = "ubuntu:${file("keys/id_rsa.pub")}"
    serial-port-enable = var.vps_serial-port-enable
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("keys/id_rsa")
    host        = self.network_interface.0.nat_ip_address
    }
  }
