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

  validation {
    condition     = length([for vm in values(var.vms) : vm if vm.role == "control_plane"]) == 1
    error_message = "stage must define exactly one control_plane VM."
  }

  validation {
    condition     = length([for vm in values(var.vms) : vm if vm.role == "worker"]) >= 1
    error_message = "stage must define at least one worker VM."
  }

  validation {
    condition     = alltrue([for vm in values(var.vms) : contains(["control_plane", "worker"], vm.role)])
    error_message = "stage VM roles must be control_plane or worker."
  }

  default = {
    stage-control-plane = {
      role   = "control_plane"
      ip     = "10.20.20.10"
      mac    = "52:54:00:20:20:10"
      memory = 4096
      vcpu   = 2
    }
    stage-worker-1 = {
      role   = "worker"
      ip     = "10.20.20.11"
      mac    = "52:54:00:20:20:11"
      memory = 4096
      vcpu   = 2
    }
  }
}
