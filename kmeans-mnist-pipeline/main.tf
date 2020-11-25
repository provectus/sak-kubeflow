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
      IMAGE     = data.aws_sagemaker_prebuilt_ecr_image.kmeans.registry_path
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

data aws_sagemaker_prebuilt_ecr_image kmeans {
  repository_name = "kmeans"
}

output image {
  description = "An image to use in Kubeflow run"
  value       = data.aws_sagemaker_prebuilt_ecr_image.kmeans.registry_path
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
