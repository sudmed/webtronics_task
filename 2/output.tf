output "vps_public_ip" {
  value = [
    for instance in yandex_compute_instance.vps[*] :
    join(" ", [instance.name, instance.hostname, instance.network_interface.0.nat_ip_address])
  ]
}

output "vps_private_ip" {
  value = [
    for instance in yandex_compute_instance.vps[*] :
    join(" ", [instance.name, instance.hostname, instance.network_interface.0.ip_address])
  ]
}
