terraform {
  required_version = ">= 1.4.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.17.0"
    }
  }
}
