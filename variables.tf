variable branch {
  type        = string
  description = "describe your variable"
  default     = "init"
}

variable owner {
  type        = string
  description = "describe your variable"
  default     = "provectus"
}

variable repository {
  type        = string
  description = "describe your variable"
  default     = "kubeflow-sandbox"
}

variable aws_region {
  description = "Name the aws region (us-central-1, us-west-2 and etc.)"
  default     = "us-east-2"
}

# Name of EKS cluster (Not use underscore in naming. S3 backet name issue)
variable cluster_name {
  description = "Name of cluster"
  default     = "sandbox"
}

variable availability_zones {
  type        = list(string)
  description = "List of use avilability_zones"
  default     = ["us-east-2a", "us-east-2b"]
}

#Deploy environment name
variable environment {
  type        = string
  description = "Environment Use in tags and annotations for identify EKS cluster"
  default     = "testing"
}

#Deploy project name
variable project {
  type        = string
  description = "Project Use in tags and annotations for identify EKS cluster"
  default     = "Kubeflow"
}

variable aws_private {
  type        = string
  description = "Use private zone or public"
  default     = "false"
}

variable mainzoneid {
  type        = string
  description = "ID of main route53 zone if exist"
}

variable domains {
  description = "Domains name for ingress"
  type        = list(string)
}

variable admin_arns {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable cert_manager_email {
  type = string
}
