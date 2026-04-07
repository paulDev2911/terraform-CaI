terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}
resource "proxmox_virtual_environment_container" "lxc" {
  node_name    = var.node
  vm_id        = var.vmid
  description  = "Terraform managed | Salt: ${var.role} | ID: ${var.name}"
  tags         = var.tags
  start_on_boot = true
  started      = true
  unprivileged = true

  operating_system {
    template_file_id = var.template
    type             = "debian"
  }

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }

    dns {
      servers = [var.dns_server]
    }
  }

cpu    { cores = var.cores }

  memory {
    dedicated = var.memory_mb
    swap      = 512
  }

disk {
    datastore_id = var.storage_pool
    size         = var.disk_gb
  }
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  features {
    nesting = true
  }
}

resource "terraform_data" "salt_bootstrap" {
  depends_on = [proxmox_virtual_environment_container.lxc]

  connection {
    type        = "ssh"
    host        = split("/", var.ip)[0]
    user        = "root"
    private_key = file("~/.ssh/homelab")
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      "until apt-get update -qq; do sleep 5; done",
      "apt-get install -y -qq curl",
      "curl -fsSL https://bootstrap.saltproject.io -o /tmp/bootstrap_salt.sh",

      # Master bekommt -M flag, Minion plain
      var.role == "master"
        ? "sh /tmp/bootstrap_salt.sh -M stable"
        : "sh /tmp/bootstrap_salt.sh stable",

      # Minion config: master IP + minion ID = container name
      var.role == "minion"
        ? "mkdir -p /etc/salt && printf 'master: ${var.salt_master_ip}\nid: ${var.name}\n' > /etc/salt/minion"
        : "echo 'master config, skipping minion file'",

      var.role == "master"
        ? "systemctl enable --now salt-master"
        : "systemctl enable --now salt-minion",
    ]
  }
}