module "secrets_store_csi_driver_addon" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"
  count   = var.module_inputs.secrets_manager == "secrets-store-csi-driver" ? 1 : 0

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true

  secrets_store_csi_driver = {
    chart_version = var.module_inputs.secrets_store_csi_driver_chart_version
    set = [{
      name  = "syncSecret.enabled"
      value = true
      },
      {
        name  = "enableSecretRotation"
        value = true
    }]
  }
  secrets_store_csi_driver_provider_aws = {
    chart_version = var.module_inputs.secrets_store_csi_driver_provider_aws_chart_version
  }

  tags = var.module_inputs.tags
}

module "external_secrets_addon" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"
  count   = var.module_inputs.secrets_manager == "external-secrets" ? 1 : 0

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  enable_external_secrets = true
  external_secrets = {
    chart_version = var.module_inputs.external_secrets_chart_version
  }

  tags = var.module_inputs.tags
}

resource "aws_secretsmanager_secret" "catalog_secret" {
  name = "${var.module_inputs.cluster_name}/catalog-secret-${random_string.suffix.result}"

  tags = var.module_inputs.tags
}

resource "aws_secretsmanager_secret_version" "catalog_secret_value" {
  secret_id = aws_secretsmanager_secret.catalog_secret.id
  secret_string = jsonencode({
    username = "catalog"
    password = "5YFMdokkZMeCyhik"
  })
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create policy to access secrets and SSM parameters
resource "aws_iam_policy" "secrets_provider" {
  count = var.module_inputs.secrets_manager == "secrets-store-csi-driver" ? 1 : 0

  name        = "${var.module_inputs.cluster_name}-secrets-provider"
  description = "Policy to allow access to Secrets Manager and SSM Parameter Store"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:${var.module_inputs.partition}:secretsmanager:${var.module_inputs.region}:*:secret:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DescribeParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:${var.module_inputs.partition}:ssm:${var.module_inputs.region}:*:parameter/*"
      }
    ]
  })
}

# Create IAM role for the catalog Service Account
module "iam_assumable_role_catalog_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.44.0"
  count = var.module_inputs.secrets_manager == "secrets-store-csi-driver" ? 1 : 0

  create_role                   = true
  role_name                     = "${var.module_inputs.cluster_name}-catalog-secrets-irsa"
  provider_url                  = var.module_inputs.cluster_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.secrets_provider[0].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:catalog:catalog"]

  tags = var.module_inputs.tags
}
