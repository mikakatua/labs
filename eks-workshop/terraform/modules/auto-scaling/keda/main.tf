module "iam_assumable_role_keda" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.44.0"
  create_role                   = true
  role_name                     = "${var.module_inputs.cluster_name}-keda"
  provider_url                  = var.module_inputs.cluster_oidc_issuer_url
  role_policy_arns              = ["${var.module_inputs.iam_role_policy_prefix}/CloudWatchReadOnlyAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:keda:keda-operator"]

  tags = var.module_inputs.tags
}

resource "helm_release" "keda" {
  namespace        = "keda"
  create_namespace = true

  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = var.module_inputs.keda_chart_version
  wait       = true

  values = [
    <<-EOT
    podIdentity:
      aws:
        irsa:
          enabled: true
          roleArn: ${module.iam_assumable_role_keda.iam_role_arn}
    EOT
  ]
}
