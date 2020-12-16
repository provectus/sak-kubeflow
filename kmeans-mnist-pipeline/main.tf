variable cluster_name {
  type = string
}

variable username {
  type = string
}

locals {
  cluster_name = var.cluster_name
  username     = var.username

  name = "${local.cluster_name}-ns-${local.username}"
}

data aws_region current {}

data aws_caller_identity current {}

data aws_eks_cluster this {
  name = local.cluster_name
}

resource aws_s3_bucket data {
  bucket = local.name
  acl    = "private"

  provisioner local-exec {
    when    = destroy
    command = "aws s3 rm --recursive s3://${self.id}"
  }
}

module sa {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.25.0"
  create_role                   = true
  role_name                     = "${local.name}-sa-role"
  provider_url                  = replace(data.aws_eks_cluster.this.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.sa.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.username}:${local.username}"]
}

resource aws_iam_policy sa {
  description = "Minimal set of polices for starting Sagemaker TrainingJob"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect   = "Allow",
          Action   = ["sagemaker:*TrainingJob", "logs:*"]
          Resource = "*"
        },
        {
          "Action" = [
            "iam:PassRole"
          ],
          "Effect"   = "Allow",
          "Resource" = aws_iam_role.pipeline.arn
        }
      ]
    }
  )
}

resource kubernetes_role sa {
  metadata {
    name      = local.username
    namespace = local.username
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource kubernetes_service_account sa {
  metadata {
    name      = local.username
    namespace = local.username
    annotations = {
      "eks.amazonaws.com/role-arn" = module.sa.this_iam_role_arn
    }
  }
  automount_service_account_token = true
}

resource kubernetes_role_binding sa {
  metadata {
    name      = local.username
    namespace = local.username
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = local.username
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.username
    namespace = local.username
  }
}

resource aws_iam_role_policy pipeline {
  name = "${local.name}-training-pipeline"
  role = aws_iam_role.pipeline.id

  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Action" = [
            "s3:*",
          ],
          "Effect"   = "Allow",
          "Resource" = [aws_s3_bucket.data.arn, "${aws_s3_bucket.data.arn}/*"]
        },
        {
          "Effect" = "Allow",
          "Action" = [
            "logs:DescribeQueries",
            "logs:GetLogRecord",
            "logs:PutDestinationPolicy",
            "logs:StopQuery",
            "logs:TestMetricFilter",
            "logs:DeleteDestination",
            "logs:GetLogDelivery",
            "logs:ListLogDeliveries",
            "logs:CreateLogDelivery",
            "logs:DeleteResourcePolicy",
            "logs:PutResourcePolicy",
            "logs:DescribeExportTasks",
            "logs:GetQueryResults",
            "logs:UpdateLogDelivery",
            "logs:CancelExportTask",
            "logs:DeleteLogDelivery",
            "logs:PutDestination",
            "logs:DescribeResourcePolicies",
            "logs:DescribeDestinations"
          ],
          "Resource" = "*"
        },
        {
          "Effect" = "Allow",
          "Action" = "logs:*",
          "Resource" = [
            "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/TrainingJobs:log-stream:*",
            "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/TrainingJobs"
          ]
        }
      ]
    }
  )
}

resource aws_iam_role pipeline {
  name = "${local.name}-training-pipeline"

  assume_role_policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Action" = "sts:AssumeRole",
          "Principal" = {
            "Service" = "sagemaker.amazonaws.com"
          },
          "Effect" = "Allow",
          "Sid"    = ""
        }
      ]
    }
  )
}

resource aws_iam_role_policy_attachment sagemaker_attach {
  role       = aws_iam_role.pipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource null_resource pipeline {
  provisioner local-exec {
    working_dir = path.module
    command     = "python3 -m pip install --user virtualenv && python3 -m venv env && source env/bin/activate && pip install kfp && python3 training_pipeline.py"
    environment = {
      S3_BUCKET = aws_s3_bucket.data.id
      REGION    = data.aws_region.current.id
      IMAGE     = "${local.images[data.aws_region.current.id]}/kmeans:1"
      ROLE      = aws_iam_role.pipeline.arn
      OUTPUT    = "${abspath(path.root)}/training_pipeline.yaml"
    }
  }
}

resource null_resource dataset {
  provisioner local-exec {
    working_dir = path.module
    command     = "python3 -m pip install --user virtualenv && python3 -m venv env && source env/bin/activate && pip install sagemaker numpy && python3 dataset.py"
    environment = {
      S3_BUCKET          = aws_s3_bucket.data.id
      AWS_DEFAULT_REGION = data.aws_region.current.id
    }
  }
}

<<<<<<< HEAD
=======

>>>>>>> origin/kfp-example
locals {
  images = {
    "us-west-1"      = "632365934929.dkr.ecr.us-west-1.amazonaws.com"
    "us-west-2"      = "174872318107.dkr.ecr.us-west-2.amazonaws.com"
    "us-east-1"      = "382416733822.dkr.ecr.us-east-1.amazonaws.com"
    "us-east-2"      = "404615174143.dkr.ecr.us-east-2.amazonaws.com"
    "ap-east-1"      = "286214385809.dkr.ecr.ap-east-1.amazonaws.com"
    "ap-northeast-1" = "351501993468.dkr.ecr.ap-northeast-1.amazonaws.com"
    "ap-northeast-2" = "835164637446.dkr.ecr.ap-northeast-2.amazonaws.com"
    "ap-south-1"     = "991648021394.dkr.ecr.ap-south-1.amazonaws.com"
    "ap-southeast-1" = "475088953585.dkr.ecr.ap-southeast-1.amazonaws.com"
    "ap-southeast-2" = "712309505854.dkr.ecr.ap-southeast-2.amazonaws.com"
    "ca-central-1"   = "469771592824.dkr.ecr.ca-central-1.amazonaws.com"
    "cn-north-1"     = "390948362332.dkr.ecr.cn-north-1.amazonaws.com.cn"
    "cn-northwest-1" = "387376663083.dkr.ecr.cn-northwest-1.amazonaws.com.cn"
    "eu-central-1"   = "664544806723.dkr.ecr.eu-central-1.amazonaws.com"
    "eu-north-1"     = "669576153137.dkr.ecr.eu-north-1.amazonaws.com"
    "eu-west-1"      = "438346466558.dkr.ecr.eu-west-1.amazonaws.com"
    "eu-west-2"      = "644912444149.dkr.ecr.eu-west-2.amazonaws.com"
    "eu-west-3"      = "749696950732.dkr.ecr.eu-west-3.amazonaws.com"
    "me-south-1"     = "249704162688.dkr.ecr.me-south-1.amazonaws.com"
    "sa-east-1"      = "855470959533.dkr.ecr.sa-east-1.amazonaws.com"
    "us-gov-west-1"  = "226302683700.dkr.ecr.us-gov-west-1.amazonaws.com"
  }
}

output image {
  description = "An image to use in Kubeflow run"
  value       = "${local.images[data.aws_region.current.id]}/kmeans:1"
}

output bucket_name {
  description = "A S3 bucket with MNIST dataset and for Sagemaker outputs"
  value       = aws_s3_bucket.data.id
}

output role_arn {
  description = "A IAM role for Sagemaker execution"
  value       = aws_iam_role.pipeline.arn
}

output service_account {
  description = "A service account to use while run"
  value       = kubernetes_service_account.sa.metadata[0].name
}
