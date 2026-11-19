terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  default = "~/.ssh/id_rsa"
}

locals {
  vms = {
    vm1 = { memory = 1024, vcpu = 1 } # aplicação web
    vm2 = { memory = 2048, vcpu = 2 } # API + MySQL
  }
  ssh_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

# Imagem base Ubuntu 24.04 (baixada uma vez)
resource "libvirt_volume" "base" {
  name   = "provac-ubuntu-24.04-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Um disco por VM, derivado da imagem base
resource "libvirt_volume" "disk" {
  for_each       = local.vms
  name           = "provac-${each.key}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.base.id
  size           = 10737418240 # 10 GB
}

# cloud-init de cada VM (usa iac/cloud_init.cfg)
resource "libvirt_cloudinit_disk" "init" {
  for_each = local.vms
  name     = "provac-${each.key}-init.iso"
  pool     = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    hostname = each.key
    ssh_key  = local.ssh_key
  })
}

# As duas máquinas virtuais
resource "libvirt_domain" "vm" {
  for_each  = local.vms
  name      = "provac-${each.key}"
  memory    = each.value.memory
  vcpu      = each.value.vcpu
  cloudinit = libvirt_cloudinit_disk.init[each.key].id

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.disk[each.key].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

locals {
  vm1_ip = libvirt_domain.vm["vm1"].network_interface[0].addresses[0]
  vm2_ip = libvirt_domain.vm["vm2"].network_interface[0].addresses[0]
}

# Gera o inventário do Ansible com os IPs das VMs
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory"
  content  = <<-INV
    [vm1]
    vm1 ansible_host=${local.vm1_ip}

    [vm2]
    vm2 ansible_host=${local.vm2_ip}

    [all:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${var.ssh_private_key_path}
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
  INV
}

output "vm1_ip" {
  value = local.vm1_ip
}

output "vm2_ip" {
  value = local.vm2_ip
}

output "url_aplicacao" {
  value = "http://${local.vm1_ip}"
}
