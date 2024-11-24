locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster_name
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    # Creates an IAM role required by the AWS Load Balancer Controller
    role_name   = "${module.eks.cluster_name}-alb-controller"
    policy_name = "${module.eks.cluster_name}-alb-controller"
  }

  create_kubernetes_resources = false
}
