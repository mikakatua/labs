
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster_name
  }
}
