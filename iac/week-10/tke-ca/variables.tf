variable "secret_id" {
  default = "Your Access ID"
}

variable "secret_key" {
  default = "Your Access Key"
}

variable "region" {
  description = "The location where instacne will be created"
  default     = "ap-hongkong"
}

variable "default_instance_type" {
  # 2C4G
  default = "SA2.MEDIUM4"
}

variable "availability_zone_first" {
  default = "ap-hongkong-2"
}

variable "availability_zone_second" {
  default = "ap-hongkong-3"
}

variable "example_cluster_cidr" {
  default = "10.31.0.0/16"
}