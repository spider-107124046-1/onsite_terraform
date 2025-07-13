output "vm_ips" {
  description = "Public IPs of each VM which can be referenced by name"
  value = {
    for name, vm in google_compute_instance.vms :
    name => vm.network_interface[0].access_config[0].nat_ip
  }
}
