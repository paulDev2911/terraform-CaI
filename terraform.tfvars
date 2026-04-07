proxmox_endpoint  = "https://192.168.2.84:8006"
proxmox_token_id  = "root@pam!root"
proxmox_token_secret = "13b53885-e9fc-482f-9334-de54f3d927a4"
proxmox_insecure  = true
proxmox_node      = "homelabpaul"

lxc_template      = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
lxc_root_password = "admin"
ssh_public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGUihOPXuJCwmHLvkivJQUbk0G3RKE/AyxTzXFqnstA homelab"

salt_master_ip    = "192.168.2.100"
gateway           = "192.168.2.1"
dns_server        = "1.1.1.1"

storage_pool      = "local-lvm"