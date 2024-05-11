module "vpc" {
  source     = "../../../module/vpc"
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

module "cvm" {
  source        = "../../../module/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  password      = var.password
  memory        = 16
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_name = "week6-demo6"
}

module "k3s" {
  source      = "../../../module/k3s"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "k3s-hongkong-1"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}

module "helm" {
  source   = "../../../module/helm"
  filename = local_sensitive_file.kubeconfig.filename
  helm_charts = [
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
          "name" : "",
          "value" : "",
        }
      ]
    },
  ]
}
