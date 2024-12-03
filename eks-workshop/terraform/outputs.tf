output "environment_variables" {
  description = "Environment variables to be added to the shell"
  value = {
    AWS_REGION                       = data.aws_region.current.name
    EKS_CLUSTER_NAME                 = var.cluster_name
    EKS_DEFAULT_MNG_NAME             = keys(module.eks.eks_managed_node_groups)[0]
    LBC_CHART_VERSION                = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN                     = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    EFS_ID                           = aws_efs_file_system.efsassets.id
    CLUSTER_AUTOSCALER_CHART_VERSION = var.cluster_autoscaler_chart_version
    CLUSTER_AUTOSCALER_ROLE          = module.eks_blueprints_addons.cluster_autoscaler.iam_role_arn
  }
}
