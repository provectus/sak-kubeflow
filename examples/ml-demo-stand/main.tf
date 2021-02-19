terraform {
  backend s3 {}
}

module "sak_kubeflow" {
  source = "../.."

  cluster_name = "ml-demo-stand"
  project      = "ml-demo-stand"
  environment  = "ml-demo-stand"

  aws_region = "eu-central-1"
  availability_zones = [
    "eu-central-1a",
  "eu-central-1b"]

  owner      = "provectus"
  repository = "sak-kubeflow"
  branch     = "feature/ml-demo-stand"

  #Main route53 zone id if exist (Change It)
  mainzoneid = "Z0239428C2HQ9M3ZV8JK"

  # Name of domains (create route53 zone and ingress). Set as array, first main ingress fqdn ["example.com", "example.io"]
  domains = [
  "ds.ml.provectus.io"]

  # ARNs of users which would have admin permissions. (Change It)
  admin_arns = [
    {
      userarn  = "arn:aws:iam::334622796275:user/asaushkin"
      username = "asaushkin"
      groups = [
      "system:masters"]
    }
  ]

  # Email that would be used for LetsEncrypt notifications
  cert_manager_email = "asaushkin@provectus.com"

  cognito_users = [
    {
      email    = "asaushkin@provectus.com"
      username = "asaushkin"
      group    = "administrators"
    }
  ]

  argo_path_prefix = "examples/ml-demo-stand/"
  argo_apps_dir    = "argocd-applications"
}
