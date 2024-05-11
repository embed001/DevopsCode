# cluster-1
module "cvm_1" {
  source     = "../../module/cvm"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  password   = var.password
}

module "k3s_1" {
  depends_on  = [module.cvm_1]
  source      = "../../module/k3s"
  public_ip   = module.cvm_1.public_ip
  private_ip  = module.cvm_1.private_ip
  server_name = "k3s-hongkong-1"
}

# cluster-2
module "cvm_2" {
  source     = "../../module/cvm"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  password   = var.password
}

module "k3s_2" {
  depends_on  = [module.cvm_2]
  source      = "../../module/k3s"
  public_ip   = module.cvm_2.public_ip
  private_ip  = module.cvm_2.private_ip
  server_name = "k3s-hongkong-2"
}

# cos
module "cos" {
  source     = "../../module/cos"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  region     = "ap-hongkong"
}

# install prometheus and thanos sidecar for cluster-1
resource "null_resource" "connect_cvm_1" {
  depends_on = [module.k3s_1, module.cos]

  connection {
    host     = module.cvm_1.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
  }

  triggers = {
    script_hash = filemd5("${path.module}/cluster1.sh")
  }

  provisioner "file" {
    destination = "/tmp/object-store.yaml"
    content = templatefile(
      "${path.module}/kube-prometheus-stack/object-store.yaml.tpl",
      {
        "bucket_name" : "${module.cos.bucket_name}"
        "app_id" : "${module.cos.app_id}",
        "endpoint" : "${module.cos.endpoint}"
        "secret_id" : "${var.secret_id}"
        "secret_key" : "${var.secret_key}"
      }
    )
  }

  provisioner "file" {
    source      = "cluster1.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "file" {
    source      = "${path.module}/kube-prometheus-stack/cluster1-values.yaml"
    destination = "/tmp/values.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}

# install prometheus and thanos component for cluster-2
resource "null_resource" "connect_cvm_2" {
  depends_on = [module.k3s_2, module.cos]

  connection {
    host     = module.cvm_2.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
  }

  triggers = {
    script_hash = filemd5("${path.module}/cluster2.sh")
  }

  provisioner "file" {
    destination = "/tmp/object-store.yaml"
    content = templatefile(
      "${path.module}/kube-prometheus-stack/object-store.yaml.tpl",
      {
        "bucket_name" : "${module.cos.bucket_name}"
        "app_id" : "${module.cos.app_id}",
        "endpoint" : "${module.cos.endpoint}"
        "secret_id" : "${var.secret_id}"
        "secret_key" : "${var.secret_key}"
      }
    )
  }

  provisioner "file" {
    source      = "cluster2.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "file" {
    source      = "${path.module}/kube-prometheus-stack/cluster-observe-values.yaml"
    destination = "/tmp/values.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/kube-thanos/manifest"
    destination = "/tmp/kube-thanos"
  }

  provisioner "file" {
    destination = "/tmp/thanos-query-deployment.yaml"
    content = templatefile(
      "${path.module}/kube-thanos/tpl/thanos-query-deployment.yaml.tpl",
      {
        "public_ip" : "${module.cvm_1.public_ip}"
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}

# output
output "kube_config_cluster_1" {
  value = nonsensitive(module.k3s_1.kube_config)
}

output "kube_config_cluster_2" {
  value = nonsensitive(module.k3s_2.kube_config)
}

output "cvm_1_public_ip" {
  value = module.cvm_1.public_ip
}

output "observer_cvm_public_ip" {
  value = module.cvm_2.public_ip
}

output "ssh_password" {
  value = var.password
}

output "cluster_1_grafana" {
  value = "${module.cvm_1.public_ip}:30080, admin/password123"
}

output "observer_cluster_grafana" {
  value = "${module.cvm_2.public_ip}:30080, admin/password123"
}

output "thanos-query" {
  value = "${module.cvm_2.public_ip}:30090"
}

output "thanos-bucket" {
  value = "${module.cvm_2.public_ip}:30092"
}

output "thanos-compact" {
  value = "${module.cvm_2.public_ip}:30093"
}
