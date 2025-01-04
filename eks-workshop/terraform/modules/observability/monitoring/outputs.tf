output "amp_endpoint" {
  description = "Amazon Managed Prometheus workspace endpoint"
  value       = aws_prometheus_workspace.amp.prometheus_endpoint
}

output "adot_iam_role" {
  description = "IRSA Arn for ADOT collector"
  value       = module.iam_assumable_role_adot.iam_role_arn
}
