variable "network_name" {
  type        = string
  description = "Name of the libvirt network"
}

variable "network_mode" {
  type        = string
  description = "Libvirt network mode"
  default     = "nat"
}

variable "domain" {
  type        = string
  description = "DNS domain for the libvirt network"
  default     = "lab.local"
}

variable "addresses" {
  type        = list(string)
  description = "CIDR addresses for the libvirt network"
}

variable "dhcp_hosts" {
  type = list(object({
    hostname = string
    mac      = string
    ip       = string
  }))
  description = "Static DHCP host reservations"
  default     = []
}
