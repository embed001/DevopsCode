output "public_ip" {
  value = module.cvm.public_ip
}

output "private_ip" {
  value = module.cvm.private_ip
}

output "kubeconfig" {
  value = local_sensitive_file.kubeconfig.filename
}

output "ssh_password" {
  value = var.password
}
