variable "secret_id" {
  default = "Your Access ID"
}

variable "secret_key" {
  default = "Your Access Key"
}

variable "password" {
  default = "password123"
}

module "cvm" {
  source     = "../module/cvm"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  password   = var.password
  cpu        = 4
  memory     = 8
}

module "k3s" {
  depends_on  = [module.cvm]
  source      = "../module/k3s"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "k3s-hongkong-1"
}

output "cvm_public_ip" {
  value = module.cvm.public_ip
}

output "ssh_password" {
  value = var.password
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}