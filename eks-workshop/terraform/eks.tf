# Examples https://github.com/aws-ia/terraform-aws-eks-blueprints
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.26"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      ami_release_version      = var.ami_release_version
      ami_type                 = "AL2023_x86_64_STANDARD"
      instance_types           = ["t3.medium"]
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

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        workshop-default = "yes"
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }

    managed-spot = {
      capacity_type            = "SPOT"
      ami_type                 = "AL2023_x86_64_STANDARD"
      instance_types           = ["t3.micro", "t3.small", "t3.medium", "m5.large"] # Mixing instance types for spot capacity flexibility
      force_update_version     = true
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-spot-node"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 4
      desired_size = 2

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

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
