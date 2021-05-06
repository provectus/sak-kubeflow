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
  source        = "git::https://github.com/provectus/swiss-army-kube.git//modules/cicd/argo-cd?ref=feature/argocd"
  branch        = var.branch
  owner         = var.owner
  repository    = var.repository
  cluster_name  = module.kubernetes.cluster_name
  domains       = var.domains
  chart_version = "2.7.4"
  oidc = {
    secret = aws_cognito_user_pool_client.argocd.client_secret
    pool   = module.cognito.pool_id
    name   = "Cognito"
    id     = aws_cognito_user_pool_client.argocd.id
  }
  ingress_annotations = {
    "kubernetes.io/ingress.class"               = "alb"
    "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
    "alb.ingress.kubernetes.io/certificate-arn" = module.acm.this_acm_certificate_arn
    "alb.ingress.kubernetes.io/listen-ports" = jsonencode(
      [{ "HTTPS" = 443 }]
    )
  }
  path_prefix = var.argo_path_prefix
  apps_dir    = var.argo_apps_dir
}

module kubeflow {
  source = "git::https://github.com/provectus/swiss-army-kube.git//modules/kubeflow-operator?ref=feature/argocd"
  ingress_annotations = {
    "kubernetes.io/ingress.class"               = "alb"
    "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
    "alb.ingress.kubernetes.io/certificate-arn" = module.acm.this_acm_certificate_arn
    "alb.ingress.kubernetes.io/auth-type"       = "cognito"
    "alb.ingress.kubernetes.io/auth-idp-cognito" = jsonencode({
      "UserPoolArn"      = module.cognito.pool_arn
      "UserPoolClientId" = aws_cognito_user_pool_client.kubeflow.id
      "UserPoolDomain"   = module.cognito.domain
    })
    "alb.ingress.kubernetes.io/listen-ports" = jsonencode(
      [{ "HTTPS" = 443 }]
    )
  }
  domain = "kubeflow.${var.domains[0]}"
  argocd = module.argocd.state
}

module cluster_autoscaler {
  source            = "git::https://github.com/provectus/swiss-army-kube.git//modules/system/cluster-autoscaler?ref=feature/argocd"
  image_tag         = "v1.15.7"
  cluster_name      = module.kubernetes.cluster_name
  module_depends_on = [module.kubernetes]
  argocd            = module.argocd.state
}

module cert_manager {
  module_depends_on = [module.kubernetes]
  source            = "git::https://github.com/provectus/swiss-army-kube.git//modules/system/cert-manager?ref=feature/argocd"
  cluster_name      = module.kubernetes.cluster_name
  domains           = var.domains
  vpc_id            = module.network.vpc_id
  environment       = var.environment
  project           = var.project
  zone_id           = module.external_dns.zone_id
  email             = var.cert_manager_email
  argocd            = module.argocd.state
}

module alb_ingress {
  module_depends_on = [module.kubernetes]
  source            = "github.com/provectus/sak-alb-controller"
  cluster_name      = module.kubernetes.cluster_name
  cluster_oidc_url  = module.kubernetes.cluster_oidc_url
  domains           = var.domains
  vpc_id            = module.network.vpc_id
  certificates_arns = [module.acm.this_acm_certificate_arn]
}

module external_dns {
  source       = "git::https://github.com/provectus/swiss-army-kube.git//modules/system/external-dns?ref=feature/argocd"
  cluster_name = module.kubernetes.cluster_name
  environment  = var.environment
  project      = var.project
  vpc_id       = module.network.vpc_id
  aws_private  = var.aws_private
  domains      = var.domains
  mainzoneid   = var.mainzoneid
  argocd       = module.argocd.state
}

module cognito {
  source       = "git::https://github.com/provectus/swiss-army-kube.git//modules/cognito?ref=feature/argocd"
  domain       = var.domains[0]
  zone_id      = module.external_dns.zone_id
  cluster_name = module.kubernetes.cluster_name
  tags         = local.tags
  invite_template = {
    email_message = <<EOT
Your SAK Kubeflow username is {username} and temporary password is {####}.
Please follow the URL to access Kubeflow: https://kubeflow.${var.domains[0]}
EOT
    email_subject = "Your SAK Kubeflow temporary password"
    sms_message   = "Your SAK Kubeflow username is {username} and temporary password is {####}"
  }
}

resource aws_cognito_user_pool_client kubeflow {
  name                                 = "kubeflow"
  user_pool_id                         = module.cognito.pool_id
  callback_urls                        = ["https://kubeflow.${var.domains[0]}/oauth2/idpresponse"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  allowed_oauth_flows                  = ["code"]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = true
}

resource aws_cognito_user_pool_client argocd {
  name                                 = "argocd"
  user_pool_id                         = module.cognito.pool_id
  callback_urls                        = ["https://argocd.${var.domains[0]}/auth/callback"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "profile", "email"]
  allowed_oauth_flows                  = ["code"]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = true
}



### Optional step of populating Cognito User Pool
### will be executed locally, so aws-cli should present on the local machine
### this is an inelegant way for managing users, suitable only for demo purpose

resource "aws_cognito_user_group" "this" {
  for_each = toset(distinct(values(
    {
      for k, v in var.cognito_users :
      k => lookup(v, "group", "read-only")
    }
  )))
  name         = each.value
  user_pool_id = module.cognito.pool_id
}

resource "null_resource" "cognito_users" {
  depends_on = [module.cognito.pool_id, aws_cognito_user_group.this]
  for_each = {
    for k, v in var.cognito_users :
    format("%s:%s:%s", var.aws_region, module.cognito.pool_id, v.username) => v

  }
  provisioner "local-exec" {
    command = "aws --region ${element(split(":", each.key), 0)} cognito-idp admin-create-user --user-pool-id ${element(split(":", each.key), 1)} --username ${element(split(":", each.key), 2)} --user-attributes Name=email,Value=${each.value.email}"
  }
  provisioner "local-exec" {
    command = "aws --region ${element(split(":", each.key), 0)} cognito-idp admin-add-user-to-group --user-pool-id ${element(split(":", each.key), 1)} --username ${element(split(":", each.key), 2)} --group-name ${lookup(each.value, "group", "read-only")}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "aws --region ${element(split(":", each.key), 0)} cognito-idp admin-delete-user --user-pool-id ${element(split(":", each.key), 1)} --username ${element(split(":", each.key), 2)}"
  }
}
