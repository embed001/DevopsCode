# cluster-1
module "cvm" {
  source     = "../../module/cvm"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  password   = var.password
}

module "k3s" {
  depends_on  = [module.cvm]
  source      = "../../module/k3s"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "k3s-hongkong-1"
}

resource "null_resource" "connect_cvm" {
  depends_on = [module.k3s]

  connection {
    host     = module.cvm.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
  }

  triggers = {
    script_hash = filemd5("${path.module}/init.sh")
  }

  provisioner "file" {
    source      = "init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "file" {
    source      = "${path.module}/values/adapter-values.yaml"
    destination = "/tmp/adapter-values.yaml"
  }

  provisioner "file" {
    destination = "/tmp/values.yaml"
    content = templatefile(
      "${path.module}/values/values.yaml.tpl",
      {
        "feishu_url" : "${var.feishu_url}"
        "private_ip" : module.cvm.private_ip
      }
    )
  }

  provisioner "file" {
    source      = "${path.module}/manifest"
    destination = "/tmp/manifest"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}

# output
output "kube_config_cluster" {
  value = nonsensitive(module.k3s.kube_config)
}

output "cvm_public_ip" {
  value = module.cvm.public_ip
}

output "ssh_password" {
  value = var.password
}

output "cluster_grafana" {
  value = "${module.cvm.public_ip}:30080, admin/password123"
}

output "cluster_prometheus" {
  value = "${module.cvm.public_ip}:30090"
}

output "app" {
  value = "${module.cvm.public_ip}:30901"
}

output "third_part_prometheus_alert" {
  value = "${module.cvm.public_ip}:30902, prometheusalert/prometheusalert"
}

output "prometheus_alert" {
  value = "${module.cvm.public_ip}:30092"
}
