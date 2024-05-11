# cluster-1
module "cvm_1" {
  source     = "../../../module/cvm"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  password   = var.password
}

module "k3s_1" {
  depends_on  = [module.cvm_1]
  source      = "../../../module/k3s"
  public_ip   = module.cvm_1.public_ip
  private_ip  = module.cvm_1.private_ip
  server_name = "k3s-hongkong-1"
}

# cos
module "cos" {
  source     = "../../../module/cos"
  secret_id  = var.secret_id
  secret_key = var.secret_key
  region     = "ap-hongkong"
}

# output
resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s_1.kube_config
  filename = "${path.module}/config.yaml"
}

output "kube_config" {
  description = "kubeconfig"
  value       = "${path.module}/config.yaml"
}

output "bucket" {
  description = "cos bucket name"
  value       = "${module.cos.bucket_name}-${module.cos.app_id}"
}

output "cos_endpoint" {
  description = "cos endpoint"
  value       = "https://${module.cos.endpoint}"
}

output "cvm_public_ip" {
  value = module.cvm_1.public_ip
}

output "ssh_password" {
  value = var.password
}

output "Grafana" {
  value = "${module.cvm_1.public_ip}:30080, admin/password123"
}

output "Thanos" {
  value = "${module.cvm_1.public_ip}:30090"
}
