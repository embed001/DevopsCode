output "public_ip" {
  description = "The public ip of instance."
  value       = tencentcloud_instance.pg[0].public_ip
}
