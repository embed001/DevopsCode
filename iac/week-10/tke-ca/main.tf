terraform {
  required_providers {
    tencentcloud = {
      source = "tencentcloudstack/tencentcloud"
      version = "1.81.38"
    }
  }
}

provider "tencentcloud" {
    secret_id = var.secret_id
    secret_key = var.secret_key
    region = var.region
}

locals {
  first_vpc_id    = data.tencentcloud_vpc_subnets.vpc_one.instance_list.0.vpc_id
  first_subnet_id = data.tencentcloud_vpc_subnets.vpc_one.instance_list.0.subnet_id
  sg_id           = tencentcloud_security_group.sg.id
}

data "tencentcloud_vpc_subnets" "vpc_one" {
  is_default        = true
  availability_zone = var.availability_zone_first
}

data "tencentcloud_vpc_subnets" "vpc_two" {
  is_default        = true
  availability_zone = var.availability_zone_second
}

resource "tencentcloud_security_group" "sg" {
  name = "tf-example-np-sg"
}

resource "tencentcloud_security_group_lite_rule" "sg_rule" {
  security_group_id = tencentcloud_security_group.sg.id

  ingress = [
    # note: the following rules are for demo purpose only, please adjust them according to your actual needs
    "ACCEPT#0.0.0.0/0#ALL#ALL",
  ]

  egress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL",
  ]
}

resource "tencentcloud_kubernetes_cluster" "example" {
  vpc_id                  = local.first_vpc_id
  cluster_cidr            = var.example_cluster_cidr
  cluster_name            = "tf_example_cluster_np"
  cluster_version         = "1.26.1"
  cluster_deploy_type     = "MANAGED_CLUSTER"
  container_runtime = "containerd"
}

resource "tencentcloud_kubernetes_node_pool" "example" {
  name                     = "tf_example_node_pool"
  cluster_id               = tencentcloud_kubernetes_cluster.example.id
  max_size                 = 100 # set the node scaling range [1,6]
  min_size                 = 1
  vpc_id                   = local.first_vpc_id
  subnet_ids               = [local.first_subnet_id]
  retry_policy             = "INCREMENTAL_INTERVALS"
  desired_capacity         = 1
  enable_auto_scale        = true
  multi_zone_subnet_policy = "EQUALITY"

  auto_scaling_config {
    instance_type              = var.default_instance_type
    system_disk_type           = "CLOUD_PREMIUM"
    system_disk_size           = "50"
    orderly_security_group_ids = [local.sg_id]

    data_disk {
      disk_type = "CLOUD_PREMIUM"
      disk_size = 50
    }

    internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR"
    internet_max_bandwidth_out = 100
    public_ip_assigned         = true
    password                   = "password123"
    enhanced_security_service  = false
    enhanced_monitor_service   = false
    host_name                  = "asg-node"
    host_name_style            = "ORIGINAL"
  }

  labels = {
    "test1" = "test1",
    "test2" = "test2",
  }

  taints {
    key    = "test_taint"
    value  = "taint_value"
    effect = "PreferNoSchedule"
  }

  taints {
    key    = "test_taint2"
    value  = "taint_value2"
    effect = "PreferNoSchedule"
  }

  node_config {
    extra_args = [
      "root-dir=/var/lib/kubelet"
    ]
  }
}

resource "tencentcloud_kubernetes_cluster_endpoint" "example" {
  cluster_id                      = tencentcloud_kubernetes_cluster.example.id
  cluster_internet                = true # open the internet here
  cluster_intranet                = true
  cluster_internet_security_group = local.sg_id
  cluster_intranet_subnet_id      = local.first_subnet_id
  depends_on = [ # wait for the node pool ready
    tencentcloud_kubernetes_node_pool.example
  ]
}