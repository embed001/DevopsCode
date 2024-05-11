module "vpc" {
  source     = "../../module/vpc"
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

module "cvm" {
  source        = "../../module/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  password      = var.password
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_name = "loki"
  cpu           = 4
  memory        = 16
}

module "k3s" {
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
    source      = "./yaml/values.yaml"
    destination = "/tmp/values.yaml"
  }

  provisioner "file" {
    source      = "./yaml/loki.values.yaml"
    destination = "/tmp/loki.values.yaml"
  }

  provisioner "file" {
    source      = "./yaml/microservice.yaml"
    destination = "/tmp/microservice.yaml"
  }

  provisioner "file" {
    source      = "./yaml/microservice.raw.yaml"
    destination = "/tmp/microservice.raw.yaml"
  }

  provisioner "file" {
    source      = "init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}
