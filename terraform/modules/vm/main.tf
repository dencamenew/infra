locals {
  hostname        = var.vm_name
  fqdn            = "${var.vm_name}.${var.vm_domain}"
  base_image_name = basename(var.base_image)

  cloud_init_user_data = <<-EOF
#cloud-config
hostname: ${local.hostname}
fqdn: ${local.fqdn}
manage_etc_hosts: true
prefer_fqdn_over_hostname: true

users:
  - name: ubuntu
    ssh_authorized_keys:
      - ${var.ssh_public_key}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, sudo
    shell: /bin/bash

  - name: denis
    ssh_authorized_keys:
      - ${var.ssh_public_key}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, sudo
    shell: /bin/bash

chpasswd:
  list: |
    ubuntu:ubuntu123!
    denis:1711Denis!
  expire: false

ssh_pwauth: true
package_update: true

packages:
  - qemu-guest-agent

write_files:
  - path: /etc/hosts
    owner: root:root
    permissions: "0644"
    content: |
      127.0.0.1 localhost
      127.0.1.1 ${local.hostname} ${local.fqdn}
      ::1 localhost ip6-localhost ip6-loopback
      ff02::1 ip6-allnodes
      ff02::2 ip6-allrouters
  - path: /etc/vm-tags
    permissions: "0644"
    content: |
      %{for k, v in var.tags~}
      ${k}=${v}
      %{endfor~}

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  EOF

  cloud_init_meta_data = <<-EOF
instance-id: ${var.vm_name}
local-hostname: ${var.vm_name}
  EOF
}

resource "libvirt_cloudinit_disk" "this" {
  name      = "${var.vm_name}-cloudinit.iso"
  pool      = var.pool_name
  user_data = local.cloud_init_user_data
  meta_data = local.cloud_init_meta_data
}

resource "libvirt_volume" "this" {
  name             = "${var.vm_name}.qcow2"
  pool             = var.pool_name
  base_volume_name = local.base_image_name
  base_volume_pool = var.pool_name
  size             = var.vm_disk_size_bytes
  format           = "qcow2"
}

resource "libvirt_domain" "this" {
  name   = var.vm_name
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  cloudinit = libvirt_cloudinit_disk.this.id

  network_interface {
    network_name   = var.network_name
    mac            = var.mac_address
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.this.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
