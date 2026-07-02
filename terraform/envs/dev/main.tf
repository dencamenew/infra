module "network" {
  source = "../../modules/network"

  network_name = var.network_name
  domain       = var.network_domain
  addresses    = var.network_addresses
  dhcp_hosts = [
    for name in sort(keys(var.vms)) : {
      hostname = name
      mac      = var.vms[name].mac
      ip       = var.vms[name].ip
    }
  ]
}

module "vm" {
  for_each = var.vms

  source = "../../modules/vm"

  vm_name        = each.key
  vm_domain      = var.network_domain
  ssh_public_key = var.ssh_public_key
  vm_memory      = each.value.memory
  vm_vcpu        = each.value.vcpu
  vm_ip          = each.value.ip
  mac_address    = each.value.mac
  network_name   = module.network.name
  pool_name      = var.pool_name
  base_image     = var.base_image

  tags = {
    env   = "dev"
    owner = "denis"
    role  = each.value.role
  }
}
