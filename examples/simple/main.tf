module "sak_kubeflow" {
  source = "../.."

  cluster_name = "testcognito"

  owner      = "provectus"
  repository = "sak-kubeflow"
  branch     = "test"

  #Main route53 zone id if exist (Change It)
  mainzoneid = "Z04917561CQAI9UAF27D6"

  # Name of domains (create route53 zone and ingress). Set as array, first main ingress fqdn ["example.com", "example.io"]
  domains = ["testcognito.sak.ninja"]

  # ARNs of users which would have admin permissions. (Change It)
  admin_arns = []
  #   {
  #     userarn  = "arn:aws:iam::xxxxxxxxxxxx:user/rxxxxxxxv"
  #     username = "rxxxxxxxv"
  #     groups   = ["system:masters"]
  #   }
  # ]

  # Email that would be used for LetsEncrypt notifications
  cert_manager_email = "dkharlamov@provectus.com"

  cognito_users = [
    {
      email    = "dkharlamov@provectus.com"
      username = "dkharlamov"
      group    = "administrators"
    }
  ]

  argo_path_prefix = "examples/simple/"
  argo_apps_dir    = "argocd-applications"
}
