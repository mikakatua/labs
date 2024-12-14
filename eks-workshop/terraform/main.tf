
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
# data "aws_region" "current" {}

data "aws_eks_cluster_auth" "eks_auth" {
  name = var.cluster_name
}

locals {
  region = "eu-central-1"

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster_name
  }
}
