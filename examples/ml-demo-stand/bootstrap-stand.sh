#!/bin/bash -e

# Generates main.tf based on the main.tf.tpl template

function promptValue() {
  read -p "$1"": " $2
}

default_git_owner=${1:-provectus}
default_git_repo=${2:-sak-kubeflow}
default_zone_id=${3:-Z0239428C2HQ9M3ZV8JK}

caller_identity=$(aws sts get-caller-identity)

default_admin_arn=$(echo $caller_identity | jq -r .Arn)
default_username=${default_admin_arn##*/}
default_account_id=$(echo $caller_identity | jq -r .Account)
default_git_branch=$(git rev-parse --abbrev-ref HEAD)
default_project=$(echo ${default_git_branch##*/} | tr _ -)

default_region="eu-central-1"
default_zones='"eu-central-1a","eu-central-1b"'

read -p "Enter username ($default_username): " username
read -p "Enter account_id ($default_account_id): " account_id
read -p "Enter an EKS admin ARN ($default_admin_arn): " admin_arn

read -p "Enter region ($default_region): " region
read -p "Enter zones ($default_zones): " zones

read -p "Enter git branch ($default_git_branch): " git_branch
read -p "Enter git repo ($default_git_repo): " git_repo
read -p "Enter git owner ($default_git_owner): " git_owner
read -p "Enter zone id ($default_zone_id): " zone_id
read -p "Enter project name ($default_project): " project
export project=${project:-$default_project}

read -p "Enter cluster name ($project): " cluster
export cluster=${cluster:-$project}

read -p "Enter environment name (dev): " environment
export environment=${environment:-dev}

default_domain=${project}.ml.${default_git_owner}.io
read -p "Enter ml stand domain ($default_domain): " domain

export username=${username:-$default_username}
export account_id=${account_id:-$default_account_id}
export admin_arn=${admin_arn:-$default_admin_arn}

export git_branch=${git_branch:-$default_git_branch}
export git_repo=${git_repo:-$default_git_repo}
export git_owner=${git_owner:-$default_git_owner}

export zone_id=${zone_id:-$default_zone_id}
export domain=${domain:-$default_domain}

export region=${region:-$default_region}
export zones=${zones:-$default_zones}

envsubst <main.tf.tpl >main.tf

echo The next steps:
echo
echo 1. Run this command to bootstrap the terraform infrastructure
echo PROJECT=${project} AWS_DEFAULT_REGION=${region} make init-bootstrap-terraform-resources
echo
echo "2. Run the 'terraform apply' command to complete the infrastructure creation"
echo
