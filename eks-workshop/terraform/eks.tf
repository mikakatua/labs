module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
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

    snapshot-controller = {
      # addon_version = "v8.1.0-eksbuild.2"
      most_recent = true
    }

    aws-ebs-csi-driver = {
      # addon_version            = "v1.37.0-eksbuild.1"
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      configuration_values = jsonencode({
        defaultStorageClass = {
          enabled = true
        }
      })
    }

    aws-efs-csi-driver = {
      # addon_version            = "v2.1.0-eksbuild.1"
      most_recent              = true
      service_account_role_arn = module.efs_csi_driver_irsa.iam_role_arn
    }

    eks-pod-identity-agent = {
      # addon_version            = "v1.3.4-eksbuild"
      most_recent = true
    }

  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # create_cluster_security_group = false
  # create_node_security_group    = false

  eks_managed_node_groups = {
    default = {
      ami_release_version      = var.ami_release_version
      ami_type                 = "AL2023_x86_64_STANDARD"
      instance_types           = ["m5.large"]
      force_update_version     = true
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-ng-default"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 2
      desired_size = 1

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workshop-default = "yes"
      }
    }
    managed-spot = {
      capacity_type            = "SPOT"
      ami_type                 = "AL2023_x86_64_STANDARD"
      instance_types           = ["c5.large", "c5d.large", "c5a.large", "c5ad.large", "c6a.large"] # Mixing instance types for spot capacity flexibility
      force_update_version     = true
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-spot-node"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 4
      desired_size = 2

      taints = {
        spotInstance = {
          key    = "spotInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE" # we prefer pods not be scheduled on Spot Instances
        }
      }
    }
  }

  fargate_profiles = {
    checkout-profile = {
      selectors = [
        {
          namespace = "checkout"
          labels = {
            fargate = "yes"
          }
        }
      ]
    }
  }

  node_security_group_tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  })

  tags = local.tags
}
