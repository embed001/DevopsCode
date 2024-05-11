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
  instance_name = "cluster-1"
  cpu           = 4
  memory        = 8
}

module "k3s" {
  source      = "../../module/k3s"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "k3s-hongkong-1"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}

module "helm" {
  source   = "../../module/helm"
  filename = local_sensitive_file.kubeconfig.filename
  helm_charts = [
    # {
    #   name             = "kube-prometheus-stack"
    #   namespace        = "monitoring"
    #   repository       = "https://prometheus-community.github.io/helm-charts"
    #   chart            = "kube-prometheus-stack"
    #   create_namespace = true
    #   version          = "52.1.0"
    #   values_file      = ""
    #   set = [
    #     {
    #       "name" : "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues",
    #       "value" : "false",
    #     },
    #     {
    #       "name" : "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues",
    #       "value" : "false",
    #     }
    #   ]
    # },
    {
      name             = "ingress-ngnix"
      namespace        = "ingress-nginx"
      repository       = "https://kubernetes.github.io/ingress-nginx"
      chart            = "ingress-nginx"
      create_namespace = true
      version          = "4.7.2"
      values_file      = ""
      set = [
        {
          "name" : "controller.metrics.enabled",
          "value" : "true",
        },
        {
          "name" : "controller.metrics.serviceMonitor.enabled",
          "value" : "true",
        },
        {
          "name" : "controller.metrics.serviceMonitor.additionalLabels.release",
          "value" : "kube-prometheus-stack",
        }
      ]
    }
  ]
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
    source      = "${path.module}/yaml/kube-prometheus-stack-values.yaml"
    destination = "/tmp/kube-prometheus-stack-values.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}