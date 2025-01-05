module "cluster_autoscaler_addon" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  enable_cluster_autoscaler = true
  cluster_autoscaler = {
    role_name              = "${var.module_inputs.cluster_name}-cluster-autoscaler"
    role_name_use_prefix   = false
    policy_name            = "${var.module_inputs.cluster_name}-cluster-autoscaler"
    policy_name_use_prefix = false
  }

  tags = var.module_inputs.tags
}