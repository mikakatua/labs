output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group used by Fluent Bit"
  value       = jsondecode(module.aws_for_fluentbit_addon.aws_for_fluentbit.values).cloudWatchLogs.logGroupName
}
