locals {
  containers = {

    "master" = {
      role      = "master"
      vmid      = 100
      ip        = "192.168.1.100/24"
      cores     = 2
      memory_mb = 1024
      disk_gb   = 16
      tags      = ["salt", "infra"]
    }

    "media" = {
      role      = "minion"
      vmid      = 101
      ip        = "192.168.1.101/24"
      cores     = 4
      memory_mb = 4096
      disk_gb   = 32
      tags      = ["media", "minion"]
    }

    "docs" = {
      role      = "minion"
      vmid      = 102
      ip        = "192.168.1.102/24"
      cores     = 2
      memory_mb = 2048
      disk_gb   = 16
      tags      = ["docs", "minion"]
    }

    "vault" = {
      role      = "minion"
      vmid      = 103
      ip        = "192.168.1.103/24"
      cores     = 1
      memory_mb = 512
      disk_gb   = 8
      tags      = ["vault", "minion"]
    }

    "proxy" = {
      role      = "minion"
      vmid      = 104
      ip        = "192.168.1.104/24"
      cores     = 1
      memory_mb = 512
      disk_gb   = 8
      tags      = ["proxy", "minion"]
    }

  }

  minion_containers = { for k, v in local.containers : k => v if v.role == "minion" }
}

module "lxc" {
  source   = "./modules/lxc"
  for_each = local.containers

  name           = each.key
  vmid           = each.value.vmid
  role           = each.value.role
  ip             = each.value.ip
  gateway        = var.gateway
  dns_server     = var.dns_server
  cores          = each.value.cores
  memory_mb      = each.value.memory_mb
  disk_gb        = each.value.disk_gb
  tags           = each.value.tags
  node           = var.proxmox_node
  template       = var.lxc_template
  root_password  = var.lxc_root_password
  ssh_public_key = var.ssh_public_key
  storage_pool   = var.storage_pool
  salt_master_ip = var.salt_master_ip
}