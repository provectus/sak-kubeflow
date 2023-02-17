terraform {
  required_version = ">= 0.15"
  required_providers {
    aws        = ">= 2.66"
    helm       = ">= 1.1.1"
    kubernetes = ">= 1.12" 
    null       = ">= 3.0"
  }
}
