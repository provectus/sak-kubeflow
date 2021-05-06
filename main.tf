locals {
  tags = {
    environment = var.environment
    project     = var.project
  }
}

data aws_eks_cluster cluster {
  name = module.kubernetes.cluster_name
}

data aws_eks_cluster_auth cluster {
  name = module.kubernetes.cluster_name
}

module network {
  source             = "git::https://github.com/provectus/swiss-army-kube.git//modules/network?ref=feature/argocd"
  availability_zones = var.availability_zones
  environment        = var.environment
  project            = var.project
  cluster_name       = var.cluster_name
}

module kubernetes {
  source             = "git::https://github.com/provectus/swiss-army-kube.git//modules/kubernetes?ref=feature/argocd"
  availability_zones = var.availability_zones
  environment        = var.environment
  project            = var.project
  cluster_name       = var.cluster_name
  cluster_version    = "1.15"
  vpc_id             = module.network.vpc_id
  subnets            = module.network.private_subnets
  admin_arns         = var.admin_arns

  spot_max_cluster_size             = 5
  on_demand_common_max_cluster_size = 5
}
