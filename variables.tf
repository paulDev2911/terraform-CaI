variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_insecure" {
  type    = bool
  default = true
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "lxc_template" {
  type    = string
  default = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
}

variable "lxc_root_password" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type = string
}

variable "salt_master_ip" {
  type = string
}

variable "gateway" {
  type    = string
  default = "192.168.1.1"
}

variable "dns_server" {
  type    = string
  default = "1.1.1.1"
}

variable "storage_pool" {
  type    = string
  default = "local-zfs"
}