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
    aws-ebs-csi-driver = {
      #addon_version            = "v1.26.0-eksbuild.1"
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
    snapshot-controller = {
      # addon_version     = "v6.3.2-eksbuild.1"
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      # addon_version = "v1.15.5-eksbuild.1"
      most_recent = true
      # preserve    = true
      # # terraform not happy with PRESERVE
      # resolve_conflicts        = "NONE"
      # service_account_role_arn = "arn:aws:iam::${aws-accounts-id}:role/AmazonEKSVPCCNIRole"
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
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

  # External addons
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    chart_version = var.load_balancer_controller_chart_version
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  enable_aws_efs_csi_driver = true

  # enable_cluster_autoscaler              = true
  # cluster_autoscaler = {
  #   role_name              = "${module.eks.cluster_name}-cluster-autoscaler"
  #   role_name_use_prefix   = false
  #   policy_name            = "${module.eks.cluster_name}-cluster-autoscaler"
  #   policy_name_use_prefix = false
  # }

  enable_karpenter = true
  karpenter = {
    chart_version = var.karpenter_chart_version
    wait          = true
    values = [
      <<-EOT
      controller:
        resources:
          requests:
            cpu: 1
            memory: 1Gi
          limits:
            cpu: 1
            memory: 1Gi
      EOT
    ]
  }
  karpenter_node = {
    iam_role_additional_policies = {
      # to allow SSM into node
      "AmazonSSMManagedInstanceCore" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  enable_metrics_server = true
  metrics_server = {
    chart_version = var.metrics_server_chart_version
  }

  tags = local.tags
}
