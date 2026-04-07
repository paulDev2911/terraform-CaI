output "id"   { value = proxmox_virtual_environment_container.lxc.vm_id }
output "name" { value = var.name }
output "ip"   { value = split("/", var.ip)[0] }
output "role" { value = var.role }