# kubeflow-sandbox
Reference repository for creating EKS clusters with simple Kubeflow installation based on [Swiss-Army-Kube](https://github.com/provectus/swiss-army-kube) collection of modules.

For examining the live environment you can check the `examples/simple` folder of that repository

## Overview
This Terraform code create AWS EKS cluster and other related things as EC2 scaling groups, IAM roles, etc. All Kubernetes contents are managed by ArgoCD (which also recursively managed by himself,  can read more about that on the ArgoCD documentation page https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd), generally this repository should be interpreted as an Infrastructure as a Code repository with GitOps paradigm. Each Kubernetes manifests that placed in the `apps` folder will be deployed and future managed by ArgoCD, for that need was created umbrella-application `swiss-army-kube` (that match with the name of source Terraform module collection). For authentication is used an Amazon Cognito User Pools. Is possible to manage Cognito users and groups by Terraform code, but in that case, need to install the AWS CLI tool, because official providers do not support such resources yet.
## Preparing workspace
### Install Terrafrom
Please follow to [official Terraform site](https://learn.hashicorp.com/tutorials/terraform/install-cli)
### Install AWS-CLI
Please follow to [official AWS documentations](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
### Create configuration files
Need to create two configuration files
- `backend.hcl`
- `main.tf`
#### `backend.hcl`
``` hcl
bucket         = "bucket-with-terraform-states"
key            = "some-key/kubeflow-sandbox"
region         = "region-where-bucket-placed"
dynamodb_table = "dynamodb-table-for-locks"
```
#### `main.tf`
``` hcl
terraform {
  backend s3 {}
}

module "sak_kubeflow" {
  source = "git::https://github.com/provectus/sak-kubeflow.git?ref=init"

  cluster_name = "simple"

  owner      = "github-repo-owner"
  repository = "github-repo-name"
  branch     = "branch-name"

  #Main route53 zone id if exist (Change It)
  mainzoneid = "id-of-route53-zone"

  # Name of domains aimed for endpoints
  domains = ["sandbox.some.domain.local"]

  # ARNs of users who will have admin permissions.
  admin_arns = [
    {
      userarn  = "arn:aws:iam::<aws-account-id>:user/<username>"
      username = "<username>"
      groups   = ["system:masters"]
    }
  ]

  # Email that would be used for LetsEncrypt notifications
  cert_manager_email = "info@some.domain.local"

  # An optional list of users for Cognito Pool
  cognito_users = [
    {
      email    = "qa@some.domain.local"
      username = "qa"
      group    = "masters"
    },
    {
      email    = "developer@some.domain.local"
      username = "developer"
    }
  ]

  argo_path_prefix = "examples/simple/"
  argo_apps_dir    = "argocd-applications"
}
```
In most cases, you should also override variables related to the GitHub repository such  a `repository`, `branch` and `owner`
### Initialize Terraform
``` bash
terraform init --backend-config backend.hcl
```
This command will download all remote dependency modules
## Cluster creation
After completing all configuration steps you can execute Terraform:
``` bash
terraform apply
```
This command will create all required AWS resources such a IAM roles, policies, S3 buckets, etc.
Also, a clean EKS would be created, you can access it by updating your local kubefconfig file by the next command:
``` bash 
aws --region <region> eks update-kubeconfig --name <cluster-name>
```
and after that, you can execute `kubectl` commands.
## Post actions and accesses

As part of Terraform execution was generated a few files, by default in the `apps` folder. So, now to start deploying the actual services to EKS need to add these files to Git and push it to the repository.

ArgoCD initially configured to listen to the current repository and when new changes come to `apps` folder they trigger the synchronization process and all objects placed in that folder become created.

By default, would be created two endpoints for accessing services:
- ArgoCD  `https://argocd.some.domain.local`
- Kubeflow  `https://kubeflow.some.domain.local`

For access that URLs need to configure Cognito User Pool with the name which matches with the cluster name.
### Screenshots
![kubeflow](images/kubeflow.png)
![argocd](images/argocd.png)
