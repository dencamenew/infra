output "name" {
  description = "VM name"
  value       = libvirt_domain.this.name
}

output "id" {
  description = "VM ID"
  value       = libvirt_domain.this.id
}

output "ip" {
  description = "Primary IP address"
  value       = var.vm_ip
}

output "ips" {
  description = "All VM IP addresses"
  value       = [var.vm_ip]
}

output "mac_address" {
  description = "VM network interface MAC address"
  value       = var.mac_address
}
