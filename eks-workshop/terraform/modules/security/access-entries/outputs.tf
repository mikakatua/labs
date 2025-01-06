output "read_only_iam_role_arn" {
  description = "The Arn of the read only role"
  value       = aws_iam_role.eks_read_only.arn
}

output "carts_team_iam_role" {
  description = "The Arn of the carts team role"
  value       = aws_iam_role.eks_carts_team.arn
}

output "developers_iam_role" {
  description = "The Arn of the developers role"
  value       = aws_iam_role.eks_developers.arn
}

output "admins_iam_role" {
  description = "The Arn of the admins role"
  value       = aws_iam_role.eks_admins.arn
}