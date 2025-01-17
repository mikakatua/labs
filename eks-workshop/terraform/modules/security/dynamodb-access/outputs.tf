output "carts_dynamodb_tablename" {
  description = "The name of the DynamoDB table"
  value       = local.dynamodb_table
}

output "carts_iam_role" {
  description = "The Arn of the IAM role which provides the required permissions for the carts Service Account to read and write to DynamoDB table"
  value       = try(module.iam_assumable_role_carts_irsa[0].iam_role_arn, null)
}
