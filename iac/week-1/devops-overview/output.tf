output "public_ip" {
  description = "The public ip of instance."
  value       = tencentcloud_instance.ubuntu[0].public_ip
}

output "pg_public_ip" {
  description = "The public ip of pg instance."
  value       = module.pg.public_ip
}

output "ssh_password" {
  description = "The SSH password of instance."
  value       = var.password
}
