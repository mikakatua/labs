provider "aws" {
  default_tags {
    tags = local.tags
  }
}

terraform {
  required_version = ">= 1.4.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.72.0"
    }
  }

}
