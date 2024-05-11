output "vm1_public_ip" {
  description = "vm public ip address"
  value       = module.cvm.public_ip
}

output "vm2_public_ip" {
  description = "vm public ip address"
  value       = module.cvm_2.public_ip
}

output "vm_password" {
  description = "vm password"
  value       = "password123"
}

output "cluster1_kube_config" {
  description = "kubeconfig"
  value       = "${path.module}/config1.yaml"
}

output "cluster2_kube_config" {
  description = "kubeconfig"
  value       = "${path.module}/config2.yaml"
}

output "cluster3_kube_config" {
  description = "kubeconfig"
  value       = "${path.module}/config3.yaml"
}

