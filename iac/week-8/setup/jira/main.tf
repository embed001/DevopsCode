module "cvm" {
  source        = "../../../module/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  region        = var.region
  password      = var.password
  instance_name = "jira"
}

module "k3s" {
  source     = "../../../module/k3s"
  public_ip  = module.cvm.public_ip
  private_ip = module.cvm.private_ip
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}

module "cloudflare" {
  source = "../../../module/cloudflare"
  domain = var.domain
  prefix = var.prefix
  ip     = module.cvm.public_ip
  values = ["jira"]
}

resource "null_resource" "connect_ubuntu" {
  depends_on = [module.k3s]
  connection {
    host     = module.cvm.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
  }

  triggers = {
    script_hash = filemd5("${path.module}/init.sh.tpl")
  }

  provisioner "file" {
    destination = "/tmp/jira-values.yaml"
    content = templatefile(
      "${path.module}/yaml/values.yaml.tpl",
      {
        "prefix" : "${var.prefix}"
        "domain" : "${var.domain}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/init.sh"
    content = templatefile(
      "${path.module}/init.sh.tpl",
      {

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
