variable "libvirt_uri" {
  type        = string
  description = "Libvirt connection URI"
  default     = "qemu:///system"
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key for ubuntu user"
}

variable "pool_name" {
  type        = string
  description = "Libvirt storage pool name"
  default     = "ubuntu-pool"
}

variable "pool_path" {
  type        = string
  description = "Path to libvirt storage pool"
  default     = "/var/lib/libvirt/images/ubuntu-pool"
}

variable "base_image" {
  type        = string
  description = "Path to base qcow2 image"
  default     = "/var/lib/libvirt/images/ubuntu-pool/ubuntu-jammy-base.qcow2"
}

variable "network_name" {
  type        = string
  description = "Network name for stage environment"
  default     = "stage-net"
}

variable "network_domain" {
  type        = string
  description = "DNS domain for stage network"
  default     = "stage.lab.local"
}

variable "network_addresses" {
  type        = list(string)
  description = "CIDR addresses for stage network"
  default     = ["10.20.20.0/24"]
}

variable "vms" {
  type = map(object({
    role   = string
    ip     = string
    mac    = string
    memory = number
    vcpu   = number
  }))
  description = "Stage VM definitions"

  default = {
    stage-vm = {
      role   = "app"
      ip     = "10.20.20.10"
      mac    = "52:54:00:20:20:10"
      memory = 4096
      vcpu   = 2
    }
  }
}
