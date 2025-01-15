output "catalog_secret_name" {
  description = "The name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.catalog_secret.name
}
