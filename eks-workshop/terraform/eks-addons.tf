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
    kube-proxy = {
      #addon_version     = "v1.24.17-eksbuild.4"
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      #addon_version     = "v1.9.3-eksbuild.10"
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    # (!) aws-ebs-csi-driver is long to provision (15 min)
    aws-ebs-csi-driver = {
      #addon_version            = "v1.26.0-eksbuild.1"
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      preserve                 = false
      # configuration_values     = jsonencode({ defaultStorageClass = { enabled = true } }) # creates a storage class named ebs-csi-default-sc
    }
    snapshot-controller = {
      # addon_version     = "v6.3.2-eksbuild.1"
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      # addon_version = "v1.15.5-eksbuild.1"
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true" # increases the number of IP addresses available for Pods
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
    eks-pod-identity-agent = {
      # addon_version            = "v1.3.4-eksbuild"
      most_recent = true
    }
  }

  ## External addons

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    chart_version = var.load_balancer_controller_chart_version
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  enable_aws_efs_csi_driver = true

  enable_metrics_server = true
  metrics_server = {
    chart_version = var.metrics_server_chart_version
  }

  tags = local.tags
}
