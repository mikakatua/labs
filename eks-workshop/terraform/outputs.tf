output "environment_variables" {
  description = "Environment variables to be added to the shell"
  value = {
    AWS_REGION                       = var.aws_region
    EKS_CLUSTER_NAME                 = module.eks.cluster_name
    EKS_DEFAULT_MNG_NAME             = keys(module.eks.eks_managed_node_groups)[0]
    LBC_CHART_VERSION                = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN                     = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
    EFS_ID                           = module.efs_csi_driver.efs_id
    CLUSTER_AUTOSCALER_CHART_VERSION = var.cluster_autoscaler_chart_version
    CLUSTER_AUTOSCALER_ROLE          = try(module.cluster_autoscaler[0].cluster_autoscaler_role, null)
    KARPENTER_VERSION                = var.karpenter_chart_version
    KARPENTER_ROLE                   = try(module.karpenter[0].karpenter_role, null)
    KARPENTER_SQS_QUEUE              = try(module.karpenter[0].karpenter_sqs_queue, null)
    KEDA_CHART_VERSION               = var.keda_chart_version
    KEDA_ROLE_ARN                    = try(module.keda[0].keda_role_arn, null)
    CLOUDWATCH_LOG_GROUP_NAME        = try(module.logging[0].cloudwatch_log_group_name, null)
    AWS_ACCOUNT_ID                   = data.aws_caller_identity.current.account_id
    AMP_ENDPOINT                     = try(module.monitoring[0].amp_endpoint, null)
    ADOT_IAM_ROLE                    = try(module.monitoring[0].adot_iam_role, null)
    READ_ONLY_IAM_ROLE               = module.access_entries.read_only_iam_role_arn
    CARTS_TEAM_IAM_ROLE              = module.access_entries.carts_team_iam_role
    DEVELOPERS_IAM_ROLE              = module.access_entries.developers_iam_role
    ADMINS_IAM_ROLE                  = module.access_entries.admins_iam_role
    CARTS_DYNAMODB_TABLENAME         = module.dynamodb_access.carts_dynamodb_tablename
    CARTS_IAM_ROLE                   = module.dynamodb_access.carts_iam_role
  }
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}
