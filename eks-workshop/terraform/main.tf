
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster_name
  }
}
