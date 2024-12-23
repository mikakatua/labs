# module "karpenter" {
#   source  = "terraform-aws-modules/eks/aws//modules/karpenter"
#   version = "20.24.0"

#   cluster_name                    = module.eks.cluster_name
#   enable_pod_identity             = true
#   create_pod_identity_association = true
#   namespace                       = "karpenter" # Namespace to associate with the Karpenter Pod Identity
#   iam_role_name                   = "${module.eks.cluster_name}-karpenter-controller"
#   iam_role_use_name_prefix        = false
#   iam_policy_name                 = "${module.eks.cluster_name}-karpenter-controller"
#   iam_policy_use_name_prefix      = false
#   node_iam_role_name              = "${module.eks.cluster_name}-karpenter-node"
#   node_iam_role_use_name_prefix   = false
#   queue_name                      = "${module.eks.cluster_name}-karpenter"
#   rule_name_prefix                = "eks-workshop"

#   node_iam_role_additional_policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   tags = local.tags
# }

# resource "helm_release" "karpenter" {
#   namespace        = "karpenter"
#   create_namespace = true

#   name       = "karpenter"
#   repository = "oci://public.ecr.aws/karpenter"
#   chart      = "karpenter"
#   version    = var.karpenter_chart_version
#   wait       = true

#   values = [
#     <<-EOT
#     settings:
#       clusterName: ${module.eks.cluster_name}
#       interruptionQueueName: ${module.karpenter.queue_name}
#     controller:
#       resources:
#         requests:
#           cpu: 1
#           memory: 1Gi
#         limits:
#           cpu: 1
#           memory: 1Gi
#     EOT
#   ]
# }

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      amiSelectorTerms:
        # Select EKS optimized AL2023 AMIs with the latest version. This term is mutually
        # exclusive and can't be specified with other terms.
        - alias: al2023@latest
      role: ${module.eks_blueprints_addons.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        app.kubernetes.io/created-by: eks-workshop
  YAML

  # depends_on = [
  #   helm_release.karpenter
  # ]
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
              values: ["amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand", "spot"]
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