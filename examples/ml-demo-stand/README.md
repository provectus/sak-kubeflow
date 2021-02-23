# How to start

The main goal of the bootstrap scripts in this example folder to
have ability start the ML demo stand from the different branches 
(repos and owners). It's especially important because we want to
commit our ArgoCD application in the same branch.

1. So, the first step is creating of a new git branch

	git checkout -b feature/my-ml-demo-stand

2. Bootstrap the application. Run the script `./bootstrap-stand.sh`
and answer the questions. It modifies the main.tf and fills it with
values appropriate for you. Review the main.tf and fix any of variables
you want. 

3. Run the commands that will give you bootstrap-stand.sh script at the
end of the execution.

Usually it contains couple of the commands like this (PROJECT and 
AWS\_DEFAULT\_REGION variables will have your values accordingly):

	PROJECT=ml-demo-stand AWS_DEFAULT_REGION=eu-central-1 make init-bootstrap-terraform-resources

The command above creates an S3 bucket with enabled versioning and 
encryption at rest and DynamoDB table that allow terraform to use 
remote state.

4. The next command is:

	terraform apply

It creates VPC, EKS, roles for applications, and installs the ArgoCD helm 
chart into the EKS cluster.

5. Create Cognito users to have ability work with ArgoCD and Kubeflow. Uncomment 
the last section in the `../../custom.tf` file and run `terraform apply` again.

This command creates a new Cognito user and temporary password will be sent 
you through the email pointed in the `main.tf` file.

6. The previous command also created a new directory `argocd-applications`
with argocd applications. Theses applications are not deployed yet. 

To deploy them you should push your changes to the remote repository (you will
have a different branch name).

	git add .
	git commit -m 'My ML demo stand'
	git push origin feature/my-ml-demo-stand


7. Now, you can work with ArgoCD and Kubeflow applications. The ArgoCD application
could be accessible through the `https://argocd.<domain from main.tf>`, and kubeflow
could be accessible through the `https://kubeflow.<domain from main.tf>` URLs.

Use user and password created in the step 5 to login to these applications.



