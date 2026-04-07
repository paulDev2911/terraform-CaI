output "containers" {
  value = {
    for k, v in module.lxc : k => {
      vmid = v.id
      ip   = v.ip
      role = v.role
    }
  }
}

output "minion_ids" {
  value = [for k, v in local.minion_containers : k]
}