# Create VM in yandex.cloud
resource "yandex_compute_instance" "VPS" {
  platform_id = var.master_platform_id
  count       = var.master_count
  name        = "VPS"

  resources {
    cores         = var.master_cores
    memory        = var.master_ram
    core_fraction = var.master_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.master_boot_disk_size
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = var.master_nat
  }

  metadata = {
    ssh-keys           = "ubuntu:${file("keys/id_rsa.pub")}"
    serial-port-enable = var.master_serial-port-enable
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("keys/id_rsa")
    host        = self.network_interface.0.nat_ip_address
    }
  }
