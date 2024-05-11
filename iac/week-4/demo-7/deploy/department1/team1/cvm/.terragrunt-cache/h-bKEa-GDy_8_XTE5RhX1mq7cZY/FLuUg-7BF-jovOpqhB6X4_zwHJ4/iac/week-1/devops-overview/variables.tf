# Tencent Cloud variables.

# Change it!
variable "prefix" {
  default = "wangwei1"
}
variable "secret_id" {
  default = "Your Access ID"
}

variable "secret_key" {
  default = "Your Access Key"
}

variable "domain" {
  default = "devopscamp.us"
}

# harbor default registry name
variable "registry" {
  default = "example"
}

variable "harbor_password" {
  default = "Harbor12345"
}

variable "pg_password" {
  default = "password123"
}

variable "example_project_name" {
  default = "camp-go-example"
}

variable "cloudflare_api_key" {
  default = "4X6WtUL9U-drCyp0h6yYHXV7FFbsxWkvxy_h3Xd-"
}

variable "region" {
  description = "The location where instacne will be created"
  default     = "ap-hongkong"
}

# grafana
variable "grafana_password" {
  default = "password123"
}

# jenkins
variable "jenkins_password" {
  default = "password123"
}

# sonar
variable "sonar_password" {
  default = "password123"
}

# argocd password, do not change it!
variable "argocd_password" {
  default = "password123"
}

# cosign password, do not change it!
variable "cosign_password" {
  default = "password123"
}

# Default variables
variable "availability_zone" {
  default = "ap-hongkong-2"
}

variable "instance_charge_type" {
  type    = string
  default = "SPOTPAID"
}

variable "tags" {
  description = "A map of the tags to use for the resources that are deployed"
  type        = map(string)

  default = {
    # This value will be the tage text.
    web = "tf-web"
    dev = "tf-dev"
  }
}
# VPC Info
variable "short_name" {
  default = "tf-vpc"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# VSwitch Info
variable "web_cidr" {
  default = "10.0.1.0/24"
}

# ECS insance variables 
variable "image_id" {
  default = ""
}

variable "instance_type" {
  default = ""
}

variable "instance_name" {
  default = "terraform-cvm-k8s"
}

variable "password" {
  default = "password123"
}
