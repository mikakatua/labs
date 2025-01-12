locals {
  dynamodb_table = "${var.module_inputs.cluster_name}-carts"
}

module "iam_assumable_role_carts_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.44.0"
  count   = var.module_inputs.dynamodb_access == "irsa" ? 1 : 0

  create_role                   = true
  role_name                     = "${var.module_inputs.cluster_name}-carts-dynamo-irsa"
  provider_url                  = var.module_inputs.cluster_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.carts_dynamo.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:carts:carts"]

  tags = var.module_inputs.tags
}

module "iam_assumable_role_carts_pia" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.44.0"
  count   = var.module_inputs.dynamodb_access == "pod-identity" ? 1 : 0

  create_role             = true
  role_requires_mfa       = false
  role_name               = "${var.module_inputs.cluster_name}-carts-dynamo-pia"
  trusted_role_services   = ["pods.eks.amazonaws.com"]
  custom_role_policy_arns = [aws_iam_policy.carts_dynamo.arn]
  trusted_role_actions    = ["sts:AssumeRole", "sts:TagSession"]

  tags = var.module_inputs.tags
}

# Associate an AWS IAM role to the Service Account that will be used by the carts Pods
resource "aws_eks_pod_identity_association" "carts_dynamo" {
  count   = var.module_inputs.dynamodb_access == "pod-identity" ? 1 : 0

  cluster_name  = var.module_inputs.cluster_name
  namespace     = "carts"
  service_account = "carts"
  role_arn      = "arn:aws:iam::${var.module_inputs.account_id}:role/${var.module_inputs.cluster_name}-carts-dynamo-pia"
}

resource "aws_iam_policy" "carts_dynamo" {
  name        = "${var.module_inputs.cluster_name}-carts-dynamo"
  path        = "/"
  description = "Dynamo policy for carts application"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAPIActionsOnCart",
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": [
        "arn:${var.module_inputs.partition}:dynamodb:${var.module_inputs.region}:${var.module_inputs.account_id}:table/${local.dynamodb_table}",
        "arn:${var.module_inputs.partition}:dynamodb:${var.module_inputs.region}:${var.module_inputs.account_id}:table/${local.dynamodb_table}/index/*"
      ]
    }
  ]
}
EOF
  tags   = var.module_inputs.tags
}
