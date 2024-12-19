
module "iam_assumable_role_keda" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.44.0"
  create_role                   = true
  role_name                     = "${module.eks.cluster_name}-keda"
  provider_url                  = module.eks.cluster_oidc_issuer_url
  role_policy_arns              = ["arn:${local.partition}:iam::aws:policy/CloudWatchReadOnlyAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:keda:keda-operator"]

  tags = local.tags
}

resource "helm_release" "keda" {
  namespace        = "keda"
  create_namespace = true

  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = var.keda_chart_version
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

