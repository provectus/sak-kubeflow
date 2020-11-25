[![Maintenance](https://img.shields.io/maintenance/yes/2020?style=for-the-badge)]()
[![Apache2](https://img.shields.io/badge/license-Apache2-green.svg?style=for-the-badge)](https://www.apache.org/licenses/LICENSE-2.0)
[![Join us on Slack](https://img.shields.io/badge/%20-Join%20us%20on%20Slack-blue?style=for-the-badge&logo=slack&labelColor=5c5c5c)](https://join.slack.com/t/sak-kubeflow/shared_invite/)

<!-- Swiss-Army-Kube_README -->
**[Quickstart](./QUICKSTART.md)** • **[Provectus](https://provectus.com/)**

# Deploy Kubeflow on AWS EKS with Swiss Army Kube using Terraform

Existing ways of deploying an AWS EKS cluster with Kubeflow inside requires using at least two CLI tools (kubectl, kfctl) and restrict further cluster scalability. They make you perform a lot of manual configuration on each step, limit what resources you can add to your cluster after deployment, and don’t offer any CI/CD automation or easy replication of cluster configurations you create.  

**Swiss Army Kube for Kubeflow (SAKK)** is a free open-source Terraform-based IaC solution that allows you to declaratively set up modular ML-ready Kubeflow EKS clusters with CI/CD GitOps, that can be managed by distributed teams, replicated with a couple of clicks, and add any kind of resources post-deployment. SAKK helps to quickly bring the cluster to production and comfortably scale and manage it as you go. The product is built on top of Terraform (infrastructure as code), ArgoCD (deployment automation & management of all Kubernetes resources), and Cognito (AWS identity provider). 
    
We believe that any organization or engineer using ML should be able to focus on their pipelines and applications without having to worry too much about the nitty-gritty of infrastructure deployment. Currently, SAKK is available for the [Amazon EKS](https://aws.amazon.com/eks/) (Elastic Kubernetes Service) cluster only. We plan to expand to other platforms soon.

Swiss Army Kube for Kubeflow is based on the main [**Swiss Army Kube**](https://github.com/provectus/swiss-army-kube) repository. SAKK is a SAK modification for the Kubeflow EKS setup based on SAK's collection of modules.

<br>

## Key Features

### Deploy

* Provision an AWS EKS cluster with Kubeflow inside in minutes
* Use existing project structure to set up your ML cluster configuration
* Configure your deployment with a single `.tf` file
* Deploy with a couple of Terraform commands

### Manage

* Add any resources to your cluster before or after deployment
* Deliver your projects and apps with GitOps CI/CD automation
* Easily edit, reconfigure, rerun, add or destroy resources  
* Build your own ML training pipelines in Kubeflow on AWS EKS
* Manage your cluster with Terraform and Kubernetes CLI or ArgoCD CLI/UI

### Scale

* Replicate your cluster configuration with a couple of clicks   
* Configure and deploy as many ML clusters as you need fast 
* Scale deployments by adding new resources as modules
* Reduce your cloud infrastructure spend with spot instances 
* Maximize your workload cost-efficiency 

<br>

## How it Works

This repository is a template of a Kubeflow EKS cluster for your ML projects. Modify the `main.tf` file to set up a cluster and deploy it to AWS with Terraform commands. With this simple yet powerful workflow, you can provision as many ML-ready EKS clusters (with different settings of variables, networks, Kubernetes versions, etc.) as you want in no time.

1. Prerequisites
   + Prepare an AWS account with configured IAM user
   + Fork and clone this repository
   + Install Terraform
   + Install AWS CLI
2. Configure your EKS cluster before deployment using the repo as a template
   + Configure `backend.hcl` 
   + Configure variables in `main.tfvars` 
3. Deploy your Kubeflow Kubernetes EKS cluster with Terraform commands
4. Commit and push the repository
5. Manage your Kubernetes cluster with ArgoCD (or configure `kubectl`) and deploy your ML apps to it.  

<br>

<img src="./images/SAKK-kufeflow.gif" width="1000" height="543" />

<br>

## Get Started

Please visit our [Quickstart](./QUICKSTART.md) to get ready with prerequisites, configure your cluster, and deploy it with Terraform commands:

``` 
terraform init --backend-config backend.hcl
terraform apply
aws --region <region> eks update-kubeconfig --name <cluster-name>
```  
After the deployment, manage your Kubernetes cluster with `kubectl` CLI or Argocd CLI/UI, and your AWS cluster with AWS or Terraform CLI. 

<br>

## License

Kubeflow SAK is licensed under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0.txt).

<br>

## We Love Your Feedback!

We are always happy to hear your thoughts about SAK Kubeflow. Please join our Slack to chat. 
