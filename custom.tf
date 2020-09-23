module acm {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name               = var.domains[0]
  subject_alternative_names = ["*.${var.domains[0]}"]
  zone_id                   = module.external_dns.zone_id
  validate_certificate      = var.aws_private == "false" ? true : false
  tags                      = local.tags
}

module argocd {
  // TODO: change to main SAK repo
  source       = "git::https://github.com/RustamGimadiev/swiss-army-kube.git//modules/cicd/argo-cd?ref=feature/argocd"
  branch       = var.branch
  owner        = var.owner
  repository   = var.repository
  cluster_name = module.kubernetes.cluster_name
  domains      = var.domains
}

module cluster_autoscaler {
  // TODO: change to main SAK repo
  source            = "git::https://github.com/RustamGimadiev/swiss-army-kube.git//modules/system/cluster-autoscaler?ref=feature/argocd"
  image_tag         = "v1.15.7"
  cluster_name      = module.kubernetes.cluster_name
  module_depends_on = [module.kubernetes]
}

module alb_ingress {
  // TODO: change to main SAK repo
  module_depends_on = [module.kubernetes]
  source            = "git::https://github.com/RustamGimadiev/swiss-army-kube.git//modules/ingress/aws-alb?ref=feature/argocd"
  cluster_name      = module.kubernetes.cluster_name
  domains           = var.domains
  vpc_id            = module.network.vpc_id
  certificates_arns = [module.acm.this_acm_certificate_arn]
}

# module cert_manager {
#   source       = "git::https://github.com/RustamGimadiev/swiss-army-kube.git//modules/system/cert-manager?ref=feature/argocd"
#   cluster_name = module.kubernetes.cluster_name
# }

# module external_secrets {
#   source       = "git::https://github.com/RustamGimadiev/swiss-army-kube.git//modules/system/external-secrets?ref=feature/argocd"
#   cluster_name = module.kubernetes.cluster_name
# }

module external_dns {
  // TODO: change to main SAK repo
  source       = "git::https://github.com/RustamGimadiev/swiss-army-kube.git//modules/system/external-dns?ref=feature/argocd"
  cluster_name = module.kubernetes.cluster_name
  environment  = var.environment
  project      = var.project
  vpc_id       = module.network.vpc_id
  aws_private  = var.aws_private
  domains      = var.domains
  mainzoneid   = var.mainzoneid
}

# module nginx_ingress {
#   // TODO: change to main SAK repo
#   source = "git::https://github.com/RustamGimadiev/swiss-army-kube.git//modules/ingress/nginx?ref=feature/argocd"
# }
