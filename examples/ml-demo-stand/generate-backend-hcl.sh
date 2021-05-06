#!/bin/bash -e

# Generates backend.hcl based on the bootstrapped terraform resources

# Takes the first parameter as a Project name

function _exit() {
  echo "$2 $3 $4 $5 $6 $7 $8 $9" >&2
  exit "$1"
}

[ ! -z "$1" ] || _exit 1 "ERROR: The first parameter must be the project name"
[ ! -z "$AWS_DEFAULT_REGION" ] || _exit 2 "ERROR: You must set the region in the AWS_DEFAULT_REGION variable"

project_name="${1}"
stack_name="${1}-bootstrap-terraform"

stack_description=$(aws cloudformation describe-stacks --stack-name "${stack_name}")

bucket_name=$(echo $stack_description |
  jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "TerraformStateBucket") | .OutputValue')
bucket_key="projects/${project_name}"
region="${AWS_DEFAULT_REGION}"
lock_table=$(echo $stack_description |
  jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "LockTable") | .OutputValue')

cat <<EOT | tee backend.hcl
bucket         = "${bucket_name}"
key            = "${bucket_key}"
region         = "${region}"
dynamodb_table = "${lock_table}"
EOT

_exit 0 SUCCESS: Generating of the backend.hcl was completed
