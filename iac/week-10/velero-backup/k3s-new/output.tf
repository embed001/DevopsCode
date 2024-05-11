output "vm_public_ip" {
  description = "vm public ip address"
  value       = module.cvm.public_ip
}

output "vm_password" {
  description = "vm password"
  value       = "password123"
}

output "cluster_kube_config" {
  description = "kubeconfig"
  value       = "${path.module}/config.yaml"
}