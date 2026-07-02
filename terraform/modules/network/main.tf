resource "libvirt_network" "this" {
  name      = var.network_name
  mode      = var.network_mode
  domain    = var.domain
  addresses = var.addresses

  autostart = true

  dhcp {
    enabled = true
  }

  dynamic "dnsmasq_options" {
    for_each = length(var.dhcp_hosts) > 0 ? [1] : []
    content {
      dynamic "options" {
        for_each = var.dhcp_hosts
        content {
          option_name  = "dhcp-host"
          option_value = "${options.value.mac},${options.value.ip},${options.value.hostname}"
        }
      }
    }
  }

  dns {
    enabled = true
  }
}
