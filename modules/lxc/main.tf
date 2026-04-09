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
    type             = var.os_type
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
    inline = var.os_type == "alpine" ? [

      # Alpine Bootstrap
      "until apk update -q; do sleep 5; done",
      "apk add -q curl bash",

      # Salt installieren
      var.role == "master"
        ? "apk add -q salt-master"
        : "apk add -q salt-minion",

      # Master config
      var.role == "master"
        ? "mkdir -p /etc/salt && printf 'auto_accept: True\n' > /etc/salt/master && rc-service salt-master restart"
        : "echo 'minion, skipping master config'",

      # Minion config
      var.role == "minion"
        ? "mkdir -p /etc/salt && printf 'master: ${var.salt_master_ip}\nid: ${var.name}\n' > /etc/salt/minion"
        : "echo 'master, skipping minion config'",

      # Services aktivieren
      var.role == "master"
        ? "rc-update add salt-master default && rc-service salt-master start"
        : "rc-update add salt-minion default && rc-service salt-minion start",

      # Minion restart
      var.role == "minion"
        ? "sleep 10 && rc-service salt-minion restart"
        : "echo 'master, skipping minion restart'",

      # Temp key rausschmeissen
      "TEMP_PUB='${trimspace(tls_private_key.temp.public_key_openssh)}'",
      "grep -v \"$TEMP_PUB\" ~/.ssh/authorized_keys > /tmp/ak_clean && mv /tmp/ak_clean ~/.ssh/authorized_keys",
      "echo 'temp key removed'",

    ] : [

      # Debian Bootstrap
      "until apt-get update -qq; do sleep 5; done",
      "apt-get install -y -qq curl",

      # Salt installieren
      "curl -fsSL https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh -o /tmp/bootstrap_salt.sh",
      var.role == "master"
        ? "sh /tmp/bootstrap_salt.sh -M stable"
        : "sh /tmp/bootstrap_salt.sh stable",

      # Master config
      var.role == "master"
        ? "mkdir -p /etc/salt && printf 'auto_accept: True\n' > /etc/salt/master && systemctl restart salt-master"
        : "echo 'minion, skipping master config'",

      # Minion config
      var.role == "minion"
        ? "mkdir -p /etc/salt && printf 'master: ${var.salt_master_ip}\nid: ${var.name}\n' > /etc/salt/minion"
        : "echo 'master, skipping minion config'",

      # Services starten
      var.role == "master"
        ? "systemctl enable --now salt-master"
        : "systemctl enable --now salt-minion",

      # Minion restart
      var.role == "minion"
        ? "sleep 10 && systemctl restart salt-minion"
        : "echo 'master, skipping minion restart'",

      # Temp key rausschmeissen
      "TEMP_PUB='${trimspace(tls_private_key.temp.public_key_openssh)}'",
      "grep -v \"$TEMP_PUB\" ~/.ssh/authorized_keys > /tmp/ak_clean && mv /tmp/ak_clean ~/.ssh/authorized_keys",
      "echo 'temp key removed'",

    ]
  }
}