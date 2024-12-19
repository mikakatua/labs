
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
# data "aws_region" "current" {}

data "aws_eks_cluster_auth" "eks_auth" {
  name = var.cluster_name
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = var.aws_region

  iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"

  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster_name
  }
}
