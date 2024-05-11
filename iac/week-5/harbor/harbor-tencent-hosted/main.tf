module "vpc" {
  source     = "../../../module/vpc"
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

module "redis" {
  source     = "../../../module/redis"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  vpc_id     = module.vpc.vpc_id
  subnet_id  = module.vpc.subnet_id
}

module "postgresql" {
  source            = "../../../module/postgresql"
  secret_id         = var.secret_id
  secret_key        = var.secret_key
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.subnet_id
  security_group_id = module.vpc.security_group_id
}

module "cvm" {
  source     = "../../../module/cvm"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  password   = var.password
  cpu        = 8
  memory     = 32
  vpc_id     = module.vpc.vpc_id
  subnet_id  = module.vpc.subnet_id
}

module "cloudflare" {
  source = "../../../module/cloudflare"
  domain = var.domain
  prefix = var.prefix
  ip     = module.cvm.public_ip
  values = ["harbor"]
}

resource "null_resource" "connect_ubuntu" {
  connection {
    host     = module.cvm.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
  }

  triggers = {
    script_hash = filemd5("${path.module}/createdb.sh.tpl")
  }

  provisioner "file" {
    destination = "/tmp/createdb.sh"
    content = templatefile(
      "${path.module}/createdb.sh.tpl",
      {
        "pg_private_ip" : module.postgresql.private_access_ip
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/cloudflare-token.yaml"
    source      = "yaml/cloudflare-token.yaml"
  }

  provisioner "file" {
    destination = "/tmp/issuer.yaml"
    source      = "yaml/issuer.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createdb.sh",
      "sh /tmp/createdb.sh",
    ]
  }
}

module "k3s" {
  source      = "../../../module/k3s"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "k3s-hongkong-1"
}

module "cos" {
  source     = "../../../module/cos"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  name       = "harbor-cos"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}

// craete postgresql database for harbor
module "helm" {
  source   = "../../../module/helm"
  filename = local_sensitive_file.kubeconfig.filename
  helm_charts = [
    # {
    #   name             = "ingress-ngnix"
    #   namespace        = "ingress-nginx"
    #   repository       = "https://kubernetes.github.io/ingress-nginx"
    #   chart            = "ingress-nginx"
    #   create_namespace = true
    #   set = [
    #     {
    #       "name" : "",
    #       "value" : "",
    #     }
    #   ]
    # },
    {
      name             = "harbor"
      namespace        = "harbor"
      repository       = "https://helm.goharbor.io"
      chart            = "harbor"
      version          = "1.13.0"
      create_namespace = true
      values_file      = "${path.module}/yaml/harbor-values.yaml"
      set = [
        {
          "name" : "persistence.imageChartStorage.s3.bucket",
          "value" : "${module.cos.bucket_name}-${module.cos.app_id}",
        },
        {
          "name" : "persistence.imageChartStorage.s3.accesskey",
          "value" : "${var.secret_id}",
        },
        {
          "name" : "persistence.imageChartStorage.s3.secretkey",
          "value" : "${var.secret_key}",
        },
        {
          "name" : "persistence.imageChartStorage.s3.regionendpoint",
          "value" : "${module.cos.endpoint}",
        },
        {
          "name" : "expose.ingress.hosts.core",
          "value" : "harbor.${var.prefix}.${var.domain}",
        },
        {
          "name" : "expose.ingress.hosts.notary",
          "value" : "notary.${var.prefix}.${var.domain}",
        },
        {
          "name" : "expose.ingress.className",
          "value" : "nginx",
        },
        {
          "name" : "expose.tls.enabled",
          "value" : "true",
        },
        {
          "name" : "expose.tls.certSource",
          "value" : "secret",
        },
        {
          "name" : "expose.tls.secret.secretName",
          "value" : "harbor-secret-tls",
        },
        {
          "name" : "expose.tls.secret.notarySecretName",
          "value" : "notary-secret-tls",
        },
        {
          "name" : "externalURL",
          "value" : "https://harbor.${var.prefix}.${var.domain}"
        },
        {
          "name" : "database.type",
          "value" : "external"
        },
        {
          "name" : "database.external.host",
          "value" : module.postgresql.private_access_ip
        },
        {
          "name" : "database.external.username",
          "value" : "root123"
        },
        {
          "name" : "database.external.password",
          "value" : "Root123$"
        },
        {
          "name" : "redis.type",
          "value" : "external"
        },
        {
          "name" : "redis.external.addr",
          "value" : module.redis.private_ip
        }
      ]
    }
  ]
}
