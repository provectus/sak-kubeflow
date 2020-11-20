terraform {
  backend s3 {}
}

module "sak_kubeflow" {
  source = "../.."

  cluster_name = "simple"

  owner      = "provectus"
  repository = "sak-kubeflow"
  branch     = "master"

  #Main route53 zone id if exist (Change It)
  mainzoneid = "XXXXXXXXXXXXXXXXXXXXX"

  # Name of domains (create route53 zone and ingress). Set as array, first main ingress fqdn ["example.com", "example.io"]
  domains = ["simple.xxx.provectus.io"]

  # ARNs of users which would have admin permissions. (Change It)
  admin_arns = [
    {
      userarn  = "arn:aws:iam::xxxxxxxxxxxx:user/rxxxxxxxv"
      username = "rgimadiev"
      groups   = ["system:masters"]
    }
  ]

  # Email that would be used for LetsEncrypt notifications
  cert_manager_email = "rxxxxxxxv@provectus.com"

  cognito_users = [
    {
      email    = "rxxxxxxxv@provectus.com"
      username = "rxxxxxxxv"
      group    = "administrators"
    }
  ]

  argo_path_prefix = "examples/simple/"
  argo_apps_dir    = "argocd-applications"
}
