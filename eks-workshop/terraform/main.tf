
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
# data "aws_region" "current" {}

data "aws_eks_cluster_auth" "eks_auth" {
  name = var.cluster_name
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = var.aws_region

  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 3)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k)]
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    created-by = "eks-workshop"
    env        = var.cluster_name
  }
}

################################################################################
# Cluster
################################################################################

# Examples https://github.com/aws-ia/terraform-aws-eks-blueprints
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.26"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Fargate profiles use the cluster primary security group so these must be disabled
  create_cluster_security_group = false
  create_node_security_group    = false

  eks_managed_node_groups = {
    default = {
      ami_release_version      = var.ami_release_version
      ami_type                 = "AL2023_ARM_64_STANDARD"
      instance_types           = ["t4g.medium"] # ARM64 architecture (Graviton)
      force_update_version     = true
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-ng-default"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 5
      desired_size = 3

      update_config = {
        max_unavailable_percentage = 50
      }

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        workshop-default = "yes"
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }

    managed-spot = {
      capacity_type            = "SPOT"
      ami_type                 = "AL2023_ARM_64_STANDARD"
      instance_types           = ["t4g.small", "t4g.medium", "m6g.medium", "m6g.large"] # Mixing instance types for spot capacity flexibility
      force_update_version     = true
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-spot-node"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 2
      desired_size = 1

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
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

  # Graviton arch isn't supported on EKS Fargate currently
  # https://github.com/aws/containers-roadmap/issues/1629
  fargate_profiles = {
    checkout-profile = {
      subnet_ids = module.vpc.private_subnets
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

  cluster_tags = {
    # Tag the cluster primary security group for Karpenter auto-discovery
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = local.tags
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = var.cluster_name
  cidr = var.vpc_cidr

  azs                   = local.azs
  public_subnets        = local.public_subnets
  private_subnets       = local.private_subnets
  public_subnet_suffix  = "SubnetPublic"
  private_subnet_suffix = "SubnetPrivate"

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${var.cluster_name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${var.cluster_name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${var.cluster_name}-default" }

  public_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/elb" = "1"
  })
  private_subnet_tags = merge(local.tags, {
    "karpenter.sh/discovery"          = var.cluster_name
    "kubernetes.io/role/internal-elb" = "1"
  })

  tags = local.tags
}

################################################################################
# Modules
################################################################################

module "ebs_csi_driver" {
  source = "./modules/storage/ebs-csi-driver"

  module_inputs = {
    cluster_name      = module.eks.cluster_name
    cluster_endpoint  = module.eks.cluster_endpoint
    cluster_version   = module.eks.cluster_version
    oidc_provider_arn = module.eks.oidc_provider_arn

    tags = local.tags
  }
}

module "efs_csi_driver" {
  source = "./modules/storage/efs-csi-driver"

  module_inputs = {
    cluster_name      = module.eks.cluster_name
    cluster_endpoint  = module.eks.cluster_endpoint
    cluster_version   = module.eks.cluster_version
    oidc_provider_arn = module.eks.oidc_provider_arn

    efs_csi_chart_version       = var.efs_csi_chart_version
    azs_private_subnets         = zipmap(local.azs, module.vpc.private_subnets)
    vpc_id                      = module.vpc.vpc_id
    private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks
    tags                        = local.tags
  }
}

module "cluster_autoscaler" {
  source = "./modules/auto-scaling/cluster-autoscaler"
  count  = var.enable_cluster_autoscaler ? 1 : 0

  module_inputs = {
    cluster_name      = module.eks.cluster_name
    cluster_endpoint  = module.eks.cluster_endpoint
    cluster_version   = module.eks.cluster_version
    oidc_provider_arn = module.eks.oidc_provider_arn

    tags = local.tags
  }
}

module "karpenter" {
  source = "./modules/auto-scaling/karpenter"
  count  = var.enable_karpenter ? 1 : 0

  module_inputs = {
    cluster_name      = module.eks.cluster_name
    cluster_endpoint  = module.eks.cluster_endpoint
    cluster_version   = module.eks.cluster_version
    oidc_provider_arn = module.eks.oidc_provider_arn

    karpenter_chart_version = var.karpenter_chart_version
    partition               = local.partition
    tags                    = local.tags
  }
}

module "keda" {
  source = "./modules/auto-scaling/keda"
  count  = var.enable_keda ? 1 : 0

  module_inputs = {
    cluster_name            = module.eks.cluster_name
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

    keda_chart_version = var.keda_chart_version
    partition          = local.partition
    tags               = local.tags
  }
}

module "logging" {
  source = "./modules/observability/logging"
  count  = var.enable_logging ? 1 : 0

  module_inputs = {
    cluster_name      = module.eks.cluster_name
    cluster_endpoint  = module.eks.cluster_endpoint
    cluster_version   = module.eks.cluster_version
    oidc_provider_arn = module.eks.oidc_provider_arn

    aws_for_fluent_bit_chart_version = var.aws_for_fluent_bit_chart_version
    region                           = local.region
    tags                             = local.tags
  }
}

module "monitoring" {
  source = "./modules/observability/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  module_inputs = {
    cluster_name            = module.eks.cluster_name
    cluster_endpoint        = module.eks.cluster_endpoint
    cluster_version         = module.eks.cluster_version
    oidc_provider_arn       = module.eks.oidc_provider_arn
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

    cert_manager_chart_version           = var.cert_manager_chart_version
    opentelemetry_operator_chart_version = var.opentelemetry_operator_chart_version
    grafana_chart_version                = var.grafana_chart_version
    partition                            = local.partition
    region                               = local.region
    tags                                 = local.tags
  }
}

module "kubecost" {
  source = "./modules/observability/kubecost"
  count  = var.enable_kubecost ? 1 : 0

  module_inputs = {
    kubecost_chart_version = var.kubecost_chart_version
  }
}

module "access_entries" {
  source = "./modules/security/access-entries"

  module_inputs = {
    cluster_name = module.eks.cluster_name
    account_id   = local.account_id
    partition    = local.partition
    tags         = local.tags
  }
}

module "dynamodb_access" {
  source = "./modules/security/dynamodb-access"

  module_inputs = {
    dynamodb_access = var.dynamodb_service_access

    cluster_name            = module.eks.cluster_name
    cluster_endpoint        = module.eks.cluster_endpoint
    cluster_version         = module.eks.cluster_version
    oidc_provider_arn       = module.eks.oidc_provider_arn
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

    account_id = local.account_id
    partition  = local.partition
    region     = local.region
    tags       = local.tags
  }
}
