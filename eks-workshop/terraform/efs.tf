# Create an Amazon EFS file system

resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs"
  description = "efs security group allow access to port 2049"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "allow inbound NFS traffic"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.cluster_name}-efssecuritygroup"
    }
  )
}

resource "aws_efs_file_system" "efsassets" {
  creation_token = "${var.cluster_name}-efs-assets"
  encrypted      = true
  kms_key_id     = aws_kms_key.cmk_efs.arn

  tags = merge(
    local.tags,
    {
      Name = "${var.cluster_name}-efs-assets"
    }
  )
}

resource "aws_efs_mount_target" "efsmtpvsubnet" {
  count = length(module.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.efsassets.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_kms_key" "cmk_efs" {
  description             = "KMS CMK for EFS"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cmk_efs.json
}

resource "aws_kms_alias" "cmk_efs" {
  name          = "alias/${var.cluster_name}-cmk-efs"
  target_key_id = aws_kms_key.cmk_efs.key_id
}

data "aws_iam_policy_document" "cmk_efs" {
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          data.aws_partition.current.partition,
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    resources = ["*"]
  }
  statement {
    sid = "Allow principals to encrypt."
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["elasticfilesystem.*.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  statement {
    sid = "Allow principals to decrypt."
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["elasticfilesystem.*.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "kubectl_manifest" "efs_storage_class" {
  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${aws_efs_file_system.efsassets.id}
  directoryPerms: "700"
YAML
}
