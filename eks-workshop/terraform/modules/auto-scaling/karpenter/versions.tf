terraform {
  required_version = ">= 1.4.2"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.17.0"
    }
  }
}