# Documentation https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/main/
# Test https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/tree/main/tests/complete
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      # most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
    coredns = {
      # timeouts = {
      #   create = "25m"
      #   delete = "10m"
      # }
    }
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  enable_aws_load_balancer_controller    = true
  enable_aws_efs_csi_driver              = true
  # enable_cluster_autoscaler              = true
  # enable_karpenter                       = true
  enable_metrics_server                  = true

  aws_load_balancer_controller = {
    chart_version = var.load_balancer_controller_chart_version
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  aws_efs_csi_driver = {
    chart_version = var.efs_csi_chart_version
  }

  # cluster_autoscaler = {
  #   chart_version = var.cluster_autoscaler_chart_version
  # }

  # karpenter = {
  #   chart_version = var.karpenter_chart_version
  # }

  metrics_server = {
    chart_version = var.metrics_server_chart_version
  }

  tags = local.tags
}
