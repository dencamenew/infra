output "name" {
  description = "Created network name"
  value       = libvirt_network.this.name
}

output "id" {
  description = "Created network ID"
  value       = libvirt_network.this.id
}