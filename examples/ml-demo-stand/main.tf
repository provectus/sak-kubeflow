# Run a command "./bootstrap-stand.sh" to regenerate this file with your values

terraform {
  backend s3 {}
}

module "sak_kubeflow" {
  source = "../.."

  cluster_name = "__SHOULD_BE_REPLACED__"
  project      = "__SHOULD_BE_REPLACED__"
  environment  = "__SHOULD_BE_REPLACED__"

  aws_region = "__SHOULD_BE_REPLACED__"
  availability_zones = [ __SHOULD_BE_REPLACED__ ]

  owner      = "__SHOULD_BE_REPLACED__"
  repository = "__SHOULD_BE_REPLACED__"
  branch     = "__SHOULD_BE_REPLACED__"

  mainzoneid = "__SHOULD_BE_REPLACED__"

  domains = [ "__SHOULD_BE_REPLACED__" ]

  # ARNs of users which would have admin permissions. (Change It)
  admin_arns = [
    {
      userarn  = "__SHOULD_BE_REPLACED__"
      username = "__SHOULD_BE_REPLACED__"
      groups = ["system:masters"]
    }
  ]

  # Email that would be used for LetsEncrypt notifications
  cert_manager_email = "__SHOULD_BE_REPLACED__"

  cognito_users = [
    {
      email    = "__SHOULD_BE_REPLACED__"
      username = "__SHOULD_BE_REPLACED__"
      group    = "administrators"
    }
  ]

  argo_path_prefix = "examples/ml-demo-stand/"
  argo_apps_dir    = "argocd-applications"
}
