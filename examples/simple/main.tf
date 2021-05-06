module "sak_kubeflow" {
  source = "../.."

  cluster_name = "kubeflow"

  #Enter your repository and branch
  owner      = "provectus"
  repository = "sak-kubeflow"
  branch     = "master"

  #Main route53 zone id (Change It)
  mainzoneid = ""

  # Name of domains (create route53 zone and ingress). Set as array, first main ingress fqdn ["example.com", "example.io"]
  domains = ["kubeflow.example.com"]

  # ARNs of users which would have admin permissions. (Change It)
  admin_arns = []
  #   {
  #     userarn  = "arn:aws:iam::xxxxxxxxxxxx:user/rxxxxxxxv"
  #     username = "rxxxxxxxv"
  #     groups   = ["system:masters"]
  #   }
  # ]

  # Email that would be used for LetsEncrypt notifications
  cert_manager_email = "xxxx@example.com"

  cognito_users = [
    {
      email    = "xxxx@example.com"
      username = "xxxxx"
      group    = "administrators"
    }
  ]

  argo_path_prefix = "examples/simple/"
  argo_apps_dir    = "argocd-applications"
}
