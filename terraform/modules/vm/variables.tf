variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "vm_domain" {
  type        = string
  description = "DNS domain for VM FQDN"
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key for ubuntu user"
}

variable "vm_memory" {
  type        = number
  description = "Memory in MB"
  default     = 2048

  validation {
    condition     = var.vm_memory >= 512
    error_message = "vm_memory must be at least 512 MB."
  }
}

variable "vm_vcpu" {
  type        = number
  description = "Number of vCPUs"
  default     = 2

  validation {
    condition     = var.vm_vcpu >= 1
    error_message = "vm_vcpu must be at least 1."
  }
}

variable "vm_ip" {
  type        = string
  description = "Static IPv4 address for the VM"
}

variable "mac_address" {
  type        = string
  description = "Static MAC address for the libvirt network interface"
}

variable "network_name" {
  type        = string
  description = "Libvirt network name"
}

variable "pool_name" {
  type        = string
  description = "Libvirt storage pool name"
}

variable "base_image" {
  type        = string
  description = "Path to base qcow2 image"
}

variable "vm_disk_size_bytes" {
  type        = number
  description = "VM disk size in bytes"
  default     = 32212254720
}

variable "tags" {
  type        = map(string)
  description = "Optional tags/labels for this VM"
  default     = {}
}
