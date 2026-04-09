variable "name"           { type = string }
variable "vmid"           { type = number }
variable "role"           { type = string }
variable "node"           { type = string }
variable "template"       { type = string }
variable "ip"             { type = string }
variable "gateway"        { type = string }
variable "dns_server"     { type = string }
variable "storage_pool"   { type = string }
variable "root_password"  { type = string }
variable "ssh_public_key" { type = string }
variable "salt_master_ip" { type = string }

variable "template" {
  type    = string
  default = null
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 1024
}

variable "disk_gb" {
  type    = number
  default = 16
}

variable "tags" {
  type    = list(string)
  default = []
}