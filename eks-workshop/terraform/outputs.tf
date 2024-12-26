output "environment_variables" {
  description = "Environment variables to be added to the shell"
  value = {
    AWS_REGION           = var.aws_region
    EKS_CLUSTER_NAME     = module.eks.cluster_name
    EKS_DEFAULT_MNG_NAME = keys(module.eks.eks_managed_node_groups)[0]
    LBC_CHART_VERSION    = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN         = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    EFS_ID               = module.efs.id
    # CLUSTER_AUTOSCALER_CHART_VERSION = var.cluster_autoscaler_chart_version
    # CLUSTER_AUTOSCALER_ROLE          = module.eks_blueprints_addons.cluster_autoscaler.iam_role_arn
    KARPENTER_VERSION         = var.karpenter_chart_version
    KARPENTER_ROLE            = module.eks_blueprints_addons.karpenter.node_iam_role_name
    KARPENTER_SQS_QUEUE       = module.eks_blueprints_addons.karpenter.sqs.queue_name
    KEDA_CHART_VERSION        = var.keda_chart_version
    KEDA_ROLE_ARN             = module.iam_assumable_role_keda.iam_role_arn
    # CLOUDWATCH_LOG_GROUP_NAME = jsondecode(module.eks_blueprints_addons.aws_for_fluentbit.values).cloudWatchLogs.logGroupName
    AWS_ACCOUNT_ID            = data.aws_caller_identity.current.account_id
    AMP_ENDPOINT              = aws_prometheus_workspace.this.prometheus_endpoint
    ADOT_IAM_ROLE             = module.iam_assumable_role_adot.iam_role_arn
  }
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}
