output "environment_variables" {
  description = "Environment variables to be added to the shell"
  value = {
    EKS_CLUSTER_NAME  = var.cluster_name
    LBC_CHART_VERSION = var.load_balancer_controller_chart_version
    LBC_ROLE_ARN      = module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn
  }
}
