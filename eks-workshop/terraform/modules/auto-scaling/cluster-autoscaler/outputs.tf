output "cluster_autoscaler_role" {
  description = "The Arn of the Cluster Autoscaler IAM role"
  value       = module.cluster_autoscaler_addon.cluster_autoscaler.iam_role_arn
}
