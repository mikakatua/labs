module "aws_for_fluentbit_addon" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  enable_aws_for_fluentbit = true
  aws_for_fluentbit = {
    enable_containerinsights = true
    kubelet_monitoring       = true
    chart_version            = var.module_inputs.aws_for_fluent_bit_chart_version
  }
  aws_for_fluentbit_cw_log_group = {
    create          = true
    use_name_prefix = true
    name_prefix     = "/${var.module_inputs.cluster_name}/worker-fluentbit-logs"
    retention       = 7
  }

  enable_fargate_fluentbit = true

  tags = var.module_inputs.tags
}