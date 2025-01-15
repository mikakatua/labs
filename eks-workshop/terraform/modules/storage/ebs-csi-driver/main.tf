module "ebs_csi_driver_addon" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19"

  cluster_name      = var.module_inputs.cluster_name
  cluster_endpoint  = var.module_inputs.cluster_endpoint
  cluster_version   = var.module_inputs.cluster_version
  oidc_provider_arn = var.module_inputs.oidc_provider_arn

  eks_addons = {
    # (!) aws-ebs-csi-driver is long to provision (15 min)
    aws-ebs-csi-driver = {
      #addon_version            = "v1.26.0-eksbuild.1"
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      preserve                 = false
      # configuration_values     = jsonencode({ defaultStorageClass = { enabled = true } }) # creates a storage class named ebs-csi-default-sc
    }
    snapshot-controller = {
      # addon_version     = "v6.3.2-eksbuild.1"
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  tags = var.module_inputs.tags
}

# IAM role for EBS
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name_prefix   = "${var.module_inputs.cluster_name}-ebs-csi-"
  policy_name_prefix = "${var.module_inputs.cluster_name}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.module_inputs.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.module_inputs.tags
}

# Storage class for EBS volumes
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"

    annotations = {
      # Annotation to set gp3 as default storage class
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    encrypted = true
    fsType    = "ext4"
    type      = "gp3"
  }

  depends_on = [
    module.ebs_csi_driver_addon
  ]
}
