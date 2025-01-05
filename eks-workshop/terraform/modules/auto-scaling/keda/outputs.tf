output "keda_role_arn" {
  description = "IRSA Arn for KEDA"
  value       = module.iam_assumable_role_keda.iam_role_arn
}
