resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"
  version    = var.load_balancer_controller_chart_version

  values = [
    <<-EOT
      clusterName: ${var.cluster_name}
      serviceAccount:
        name: aws-load-balancer-controller-sa
        annotations:
          eks.amazonaws.com/role-arn: ${module.eks_blueprints_addons.aws_load_balancer_controller.iam_role_arn}
    EOT
  ]

  wait = true
}
