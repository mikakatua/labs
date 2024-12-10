output "environment_variables" {
  description = "Environment variables to be added to the shell"
  value = {
    AWS_REGION                       = data.aws_region.current.name
    EKS_CLUSTER_NAME                 = module.eks.cluster_name
    EKS_DEFAULT_MNG_NAME             = keys(module.eks.eks_managed_node_groups)[0]
    LBC_CHART_VERSION                = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN                     = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    EFS_ID                           = aws_efs_file_system.efsassets.id
    CLUSTER_AUTOSCALER_CHART_VERSION = var.cluster_autoscaler_chart_version
    CLUSTER_AUTOSCALER_ROLE          = module.eks_blueprints_addons.cluster_autoscaler.iam_role_arn
    KARPENTER_VERSION                = var.karpenter_chart_version
    KARPENTER_ROLE                   = module.karpenter.node_iam_role_name
    KARPENTER_SQS_QUEUE              = module.karpenter.queue_name
  }
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks.cluster_name}"
}
