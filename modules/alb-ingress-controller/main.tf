
data aws_eks_cluster this {
  name = var.cluster_name
}

module alb_ingress_controller_oidc_binding {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.6.0"
  create_role                   = true
  role_name                     = "${var.cluster_name}_${var.name}"
  provider_url                  = replace(data.aws_eks_cluster.this.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.this.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.namespace}:${var.name}"]
}

resource aws_iam_policy this {
  depends_on = [
    var.module_depends_on
  ]
  name_prefix = var.name
  description = "EKS ${var.name} policy for cluster ${data.aws_eks_cluster.this.id}"
  policy      = data.aws_iam_policy_document.this.json
}

data aws_iam_policy_document this {
  statement {
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebACL",
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
      "cognito-idp:DescribeUserPoolClient",
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "tag:GetResources",
      "tag:TagResources",
      "waf:GetWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:DescribeProtection",
      "shield:GetSubscriptionState",
      "shield:DeleteProtection",
      "shield:CreateProtection",
      "shield:DescribeSubscription",
      "shield:ListProtections"
    ]

    resources = ["*"]
  }
}

resource local_file rbac {
  depends_on = [
    var.module_depends_on
  ]
  content = templatefile("${path.module}/rbac-role.yaml.tpl",
    {
      role_arn = module.alb_ingress_controller_oidc_binding.this_iam_role_arn
    }
  )
  filename = "${path.root}/${var.argocd.path}/${var.name}/rbac-role.yaml"
}

resource local_file alb-ingress-controller {
  depends_on = [
    var.module_depends_on
  ]
  content = templatefile("${path.module}/alb-ingress-controller.yaml.tpl",
    {
      cluster_name = var.cluster_name,
      region       = var.region,
      vpc_id       = var.vpc_id
    }
  )
  filename = "${path.root}/${var.argocd.path}/${var.name}/alb-ingress-controller.yaml"
}

resource local_file argo-application {
  depends_on = [
    var.module_depends_on
  ]
  content = templatefile("${path.module}/argo-application.yaml.tpl",
    {
      path     = "${var.argo_path_prefix}${var.argocd.path}/${var.name}",
      repo     = "https://github.com/${var.owner}/${var.repository}",
      revision = var.branch
    }
  )
  filename = "${path.root}/${var.argocd.path}/${var.name}.yaml"
}

