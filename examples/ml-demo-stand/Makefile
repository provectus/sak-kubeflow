PROJECT ?= ml-demo-stand
AWS_DEFAULT_REGION ?= eu-central-1
STACK_NAME ?= $(PROJECT)-bootstrap-terraform


init-bootstrap-terraform-resources:
	aws cloudformation --region $(AWS_DEFAULT_REGION) create-stack --stack-name $(STACK_NAME) \
		--parameters \
			ParameterKey=Project,ParameterValue=$(PROJECT) \
		--template-body file://./terraform-init.yaml --disable-rollback

	aws cloudformation --region $(AWS_DEFAULT_REGION) wait stack-create-complete --stack-name $(STACK_NAME)
	aws cloudformation --region $(AWS_DEFAULT_REGION) describe-stacks --stack-name $(STACK_NAME)
	./generate-backend-hcl.sh $(PROJECT)
	terraform init -backend-config=backend.hcl

update-bootstrap-terraform-resource:
	aws cloudformation --region $(AWS_DEFAULT_REGION) update-stack --stack-name $(STACK_NAME) \
		--parameters \
			ParameterKey=Project,ParameterValue=$(PROJECT) \
		--template-body file://./terraform-init.yaml
	./generate-backend-hcl.sh $(PROJECT)
	terraform init -backend-config=backend.hcl

	aws cloudformation --region $(AWS_DEFAULT_REGION) wait stack-update-complete --stack-name $(STACK_NAME)
	aws cloudformation --region $(AWS_DEFAULT_REGION) describe-stacks --stack-name $(STACK_NAME)

delete-bootstrap-terraform-resource:
	aws cloudformation --region $(AWS_DEFAULT_REGION) delete-stack --stack-name $(STACK_NAME)
	aws cloudformation --region $(AWS_DEFAULT_REGION) wait stack-delete-complete --stack-name $(STACK_NAME)

