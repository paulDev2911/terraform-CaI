terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

resource "tls_private_key" "temp" {
  algorithm = "ED25519"
}

resource "proxmox_virtual_environment_container" "lxc" {
  node_name     = var.node
  vm_id         = var.vmid
  description   = "Terraform managed | Salt: ${var.role} | ID: ${var.name}"
  tags          = var.tags
  start_on_boot = true
  started       = true
  unprivileged  = true

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
      keys = [
        tls_private_key.temp.public_key_openssh,
        var.ssh_public_key,
      ]
      password = var.root_password
    }

    dns {
      servers = [var.dns_server]
    }
  }

  cpu {
    cores = var.cores
  }

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
    private_key = tls_private_key.temp.private_key_openssh
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      # Salt installieren
      "until apt-get update -qq; do sleep 5; done",
      "apt-get install -y -qq curl",
      "curl -fsSL https://bootstrap.saltproject.io -o /tmp/bootstrap_salt.sh",

      var.role == "master"
        ? "sh /tmp/bootstrap_salt.sh -M stable"
        : "sh /tmp/bootstrap_salt.sh stable",

      var.role == "minion"
        ? "mkdir -p /etc/salt && printf 'master: ${var.salt_master_ip}\nid: ${var.name}\n' > /etc/salt/minion"
        : "echo 'master, skipping minion config'",

      var.role == "master"
        ? "systemctl enable --now salt-master"
        : "systemctl enable --now salt-minion",

      # Temp key aus authorized_keys rausschmeissen
      "TEMP_PUB='${trimspace(tls_private_key.temp.public_key_openssh)}'",
      "grep -v \"$TEMP_PUB\" ~/.ssh/authorized_keys > /tmp/ak_clean && mv /tmp/ak_clean ~/.ssh/authorized_keys",
      "echo 'temp key removed'",
    ]
  }
}