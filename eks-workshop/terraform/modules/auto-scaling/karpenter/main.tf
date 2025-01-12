module "karpenter_addon" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  enable_karpenter = true
  karpenter = {
    chart_version = var.module_inputs.karpenter_chart_version
    wait          = true
    values = [
      <<-EOT
      nodeSelector:
        karpenter.sh/controller: 'true'
      controller:
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1
            memory: 1Gi
      EOT
    ]
  }
  karpenter_node = {
    iam_role_additional_policies = {
      # to allow connect to Nodes via Session Manager
      "AmazonSSMManagedInstanceCore" = "arn:${var.module_inputs.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  tags = var.module_inputs.tags
}

# Required EKS Access Entry for Karpenter role
# See https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/issues/389
resource "aws_eks_access_entry" "karpenter" {
  cluster_name  = var.module_inputs.cluster_name
  principal_arn = module.karpenter_addon.karpenter.node_iam_role_arn
  type          = "EC2_LINUX"

  tags          = var.module_inputs.tags
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiSelectorTerms:
        # Select EKS optimized AL2023 AMIs with specific version
        # https://github.com/awslabs/amazon-eks-ami/releases
        - alias: al2023@v20241225
      role: ${module.karpenter_addon.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.module_inputs.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.module_inputs.cluster_name}
      tags:
        app.kubernetes.io/created-by: eks-workshop
  YAML
  depends_on = [
    module.karpenter_addon
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        metadata:
          # Labels are are applied to all nodes
          labels:
            type: karpenter
        spec:
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["arm64", "amd4"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["c", "m", "r"]
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["2"]
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          expireAfter: 720h # 30 * 24h = 720h
      limits:
        cpu: 1000
        memory: 1000Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 1m
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
