# Create IAM roles for:
# - AWS Load Balancer Controller
# - Kubernetes Cluster Autoscaler
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name   = "${module.eks.cluster_name}-alb-controller"
    policy_name = "${module.eks.cluster_name}-alb-controller"
  }

  enable_cluster_autoscaler = true
  cluster_autoscaler = {
    role_name              = "${module.eks.cluster_name}-cluster-autoscaler"
    role_name_use_prefix   = false
    policy_name            = "${module.eks.cluster_name}-cluster-autoscaler"
    policy_name_use_prefix = false
  }

  create_kubernetes_resources = false

  tags = local.tags
}

# Create the IAM role needed for the EBS CSI driver addon
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix   = "${module.eks.cluster_name}-ebs-csi-"
  policy_name_prefix = "${module.eks.cluster_name}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

# Create an IAM role for the Amazon EFS CSI driver
module "efs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix   = "${module.eks.cluster_name}-efs-csi-"
  policy_name_prefix = "${module.eks.cluster_name}-efs-csi-"

  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = local.tags
}
