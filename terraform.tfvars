cluster_name = "sandbox"
branch = "example"

#Main route53 zone id if exist (Change It)
mainzoneid = "Z02149423PVQ0YMP19F13"

# Name of domains (create route53 zone and ingress). Set as array, first main ingress fqdn ["example.com", "example.io"]
domains = ["sandbox.edu.provectus.io"]

# ARNs of users which would have admin permissions. (Change It)
admin_arns = [
  {
    userarn  = "arn:aws:iam::245582572290:user/rgimadiev"
    username = "rgimadiev"
    groups   = ["system:masters"]
  }
]

# Email that would be used for LetsEncrypt notifications
cert_manager_email = "rgimadiev@provectus.com"
