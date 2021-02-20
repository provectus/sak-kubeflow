terraform {
  backend s3 {}
}

module "sak_kubeflow" {
  source = "../.."

  cluster_name = "${cluster}"
  project      = "${project}"
  environment  = "${environment}"

  aws_region = "${region}"
  availability_zones = [ ${zones} ]

  owner      = "${git_owner}"
  repository = "${git_repo}"
  branch     = "${git_branch}"

  mainzoneid = "${zone_id}"

  domains = [ "${domain}" ]

  # ARNs of users which would have admin permissions. (Change It)
  admin_arns = [
    {
      userarn  = "${admin_arn}"
      username = "${username}"
      groups = ["system:masters"]
    }
  ]

  # Email that would be used for LetsEncrypt notifications
  cert_manager_email = "${username}@${git_owner}.com"

  cognito_users = [
    {
      email    = "${username}@${git_owner}.com"
      username = "${username}"
      group    = "administrators"
    }
  ]

  argo_path_prefix = "examples/ml-demo-stand/"
  argo_apps_dir    = "argocd-applications"
}
