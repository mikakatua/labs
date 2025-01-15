data "http" "kubecost_eks_values" {
  url = "https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/v${var.module_inputs.kubecost_chart_version}/cost-analyzer/values-eks-cost-monitoring.yaml"
}

resource "helm_release" "kubecost" {
  namespace        = "kubecost"
  create_namespace = true

  name       = "kubecost"
  repository = "https://kubecost.github.io/cost-analyzer"
  chart      = "cost-analyzer"
  version    = var.module_inputs.kubecost_chart_version
  wait       = true

  values = [
    data.http.kubecost_eks_values.response_body, # Use downloaded YAML content
    file("${path.module}/values.yaml")           # Local values override
  ]
}

