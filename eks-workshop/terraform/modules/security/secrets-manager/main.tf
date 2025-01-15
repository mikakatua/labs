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
  }
  secrets_store_csi_driver_provider_aws = {
    chart_version = var.module_inputs.secrets_store_csi_driver_provider_aws_chart_version
  }

  tags = var.module_inputs.tags
}

module "secrets_manager_addon" {
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
    username = "catalog_user"
    password = "default_password"
  })
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
