output "vms" {
  description = "Stage VM inventory data"
  value = {
    for name, vm in module.vm : name => {
      name        = vm.name
      ip          = vm.ip
      ips         = vm.ips
      mac_address = vm.mac_address
      role        = var.vms[name].role
    }
  }
}

output "network_name" {
  description = "Stage network name"
  value       = module.network.name
}
