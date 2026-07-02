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
  description = "Network name for dev environment"
  default     = "dev-net"
}

variable "network_domain" {
  type        = string
  description = "DNS domain for dev network"
  default     = "dev.lab.local"
}

variable "network_addresses" {
  type        = list(string)
  description = "CIDR addresses for dev network"
  default     = ["10.10.10.0/24"]
}

variable "vms" {
  type = map(object({
    role   = string
    ip     = string
    mac    = string
    memory = number
    vcpu   = number
  }))
  description = "Kubernetes VM definitions"

  default = {
    k8s-master-1 = {
      role   = "control_plane"
      ip     = "10.10.10.10"
      mac    = "52:54:00:10:10:10"
      memory = 4096
      vcpu   = 2
    }
    k8s-worker-1 = {
      role   = "worker"
      ip     = "10.10.10.11"
      mac    = "52:54:00:10:10:11"
      memory = 4096
      vcpu   = 2
    }
    k8s-worker-2 = {
      role   = "worker"
      ip     = "10.10.10.12"
      mac    = "52:54:00:10:10:12"
      memory = 4096
      vcpu   = 2
    }
  }
}
