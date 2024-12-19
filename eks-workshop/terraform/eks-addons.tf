# Documentation https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/main/
# Test https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/tree/main/tests/complete
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
  # enable_aws_efs_csi_driver           = true
  # enable_cluster_autoscaler              = true
  # enable_karpenter      = true
  enable_metrics_server = true

  # cluster_autoscaler = {
  #   role_name              = "${module.eks.cluster_name}-cluster-autoscaler"
  #   role_name_use_prefix   = false
  #   policy_name            = "${module.eks.cluster_name}-cluster-autoscaler"
  #   policy_name_use_prefix = false
  # }

  aws_load_balancer_controller = {
    chart_version = var.load_balancer_controller_chart_version
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  # karpenter = {
  #   chart_version = var.karpenter_chart_version
  #   wait          = true
  #   values = [
  #     <<-EOT
  #     controller:
  #       resources:
  #         requests:
  #           cpu: 1
  #           memory: 1Gi
  #         limits:
  #           cpu: 1
  #           memory: 1Gi
  #     EOT
  #   ]
  # }

  metrics_server = {
    chart_version = var.metrics_server_chart_version
  }

  tags = local.tags
}
