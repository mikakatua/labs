module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  enable_aws_efs_csi_driver = true
  aws_efs_csi_driver = {
    chart_version = var.module_inputs.efs_csi_chart_version
  }

  tags = var.module_inputs.tags
}

# Create an Amazon EFS file system
module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.1"

  name           = "${var.module_inputs.cluster_name}-efs"
  creation_token = "${var.module_inputs.cluster_name}-efs-token"

  # Mount targets / security group
  mount_targets = {
    for k, v in var.module_inputs.azs_private_subnets : k => { subnet_id = v }
  }
  security_group_description = "efs security group allow access to port 2049"
  security_group_vpc_id      = var.module_inputs.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.module_inputs.private_subnets_cidr_blocks
    }
  }

  tags = var.module_inputs.tags
}

resource "kubernetes_storage_class" "efs" {
  metadata {
    name = "efs"
  }

  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap" # Dynamic provisioning
    fileSystemId     = module.efs.id
    directoryPerms   = "700"
  }

  mount_options = [
    "iam"
  ]

  depends_on = [
    module.eks_blueprints_addons
  ]
}
