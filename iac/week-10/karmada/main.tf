module "vpc" {
  source     = "../../module/vpc"
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

module "cvm" {
  source        = "../../module/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  password      = var.password
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_name = "cluster-1"
  cpu           = 2
  memory        = 4
}

module "k3s" {
  source      = "./module/k3s-1"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "k3s-hongkong-1"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config1.yaml"
}

module "cvm_2" {
  source        = "../../module/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  password      = var.password
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_name = "cluster-2"
  cpu           = 2
  memory        = 4
}

module "cvm_3" {
  source        = "../../module/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  password      = var.password
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_name = "cluster-3"
  cpu           = 2
  memory        = 4
}

module "k3s-2" {
  source      = "./module/k3s-2"
  public_ip   = module.cvm_2.public_ip
  private_ip  = module.cvm_2.private_ip
  server_name = "k3s-hongkong-2"
}

module "k3s-3" {
  source      = "./module/k3s-3"
  public_ip   = module.cvm_3.public_ip
  private_ip  = module.cvm_3.private_ip
  server_name = "k3s-hongkong-3"
}

resource "local_sensitive_file" "kubeconfig2" {
  content  = module.k3s-2.kube_config
  filename = "${path.module}/config2.yaml"
}

resource "local_sensitive_file" "kubeconfig3" {
  content  = module.k3s-3.kube_config
  filename = "${path.module}/config3.yaml"
}