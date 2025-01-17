output "catalog_secret_name" {
  description = "The name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.catalog_secret.name
}

output "catalog_iam_role" {
  description = "The Arn of the IAM role which provides the required permissions for the catalog Service Account to access AWS Secrets Manager"
  value       = try(module.iam_assumable_role_catalog_irsa[0].iam_role_arn, null)
}
