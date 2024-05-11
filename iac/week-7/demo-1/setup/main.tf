module "cvm" {
  source     = "../../../module/cvm"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  region     = var.region
  password   = var.password
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

module "helm" {
  source           = "../../../module/helm"
  filename         = local_sensitive_file.kubeconfig.filename
  kubernetes_ready = module.k3s.kubernetes_ready
  helm_charts = [
    {
      name             = "sealed-secrets"
      namespace        = "kube-system"
      repository       = "https://bitnami-labs.github.io/sealed-secrets"
      chart            = "sealed-secrets"
      values_file      = ""
      version          = "2.13.0"
      create_namespace = true
      set = [
        {
          "name" : "fullnameOverride",
          "value" : "sealed-secrets-controller",
        }
      ]
    },
    {
      name             = "external-secrets"
      namespace        = "external-secrets"
      repository       = "https://charts.external-secrets.io"
      chart            = "external-secrets"
      values_file      = ""
      version          = "0.9.5"
      create_namespace = true
      set = [
        {
          "name" : "",
          "value" : "",
        }
      ]
    },
    {
      name             = "vault"
      namespace        = "vault"
      repository       = "https://helm.releases.hashicorp.com"
      chart            = "vault"
      values_file      = ""
      version          = "0.25.0"
      create_namespace = true
      set = [
        {
          "name" : "",
          "value" : "",
        }
      ]
    },
    {
      name             = "falcosecurity"
      namespace        = "falcosecurity"
      repository       = "https://falcosecurity.github.io/charts"
      chart            = "falco"
      values_file      = ""
      version          = "3.7.1"
      create_namespace = true
      set = [
        {
          "name" : "",
          "value" : "",
        }
      ]
    },
  ]
}
