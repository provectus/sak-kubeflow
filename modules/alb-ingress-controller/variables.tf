variable module_depends_on {
  default = []
}

variable cluster_name {
  description = "Name of the kubernetes cluster"
}

variable vpc_id {
  description = "domain name for ingress"
}

variable "region" {
  description = "controller region"
}

variable "namespace" {
  type        = string
  description = ""
  default     = "kube-system"
}

variable "name" {
  type = string
  default = "alb-ingress-controller"
}

variable argocd {
  type        = map(string)
  description = "A set of variables for enabling ArgoCD"
  default = {
    namespace  = ""
    path       = ""
    repository = ""
    branch     = ""
  }
}

variable "branch" {}
variable "owner" {}
variable "repository" {}
variable "argo_path_prefix" {}
