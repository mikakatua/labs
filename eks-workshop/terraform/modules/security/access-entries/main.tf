data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    # This is a convenient way to grant permissions to the whole account without specifying individual users or roles.
    # The "root" signifies any principal (user or role) within the specified AWS account.
    principals {
      type        = "AWS"
      identifiers = ["arn:${var.module_inputs.partition}:iam::${var.module_inputs.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "eks_developers" {
  name               = "${var.module_inputs.cluster_name}-developers"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.module_inputs.tags
}

resource "aws_iam_role" "eks_read_only" {
  name               = "${var.module_inputs.cluster_name}-read-only"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.module_inputs.tags
}

resource "aws_iam_role" "eks_carts_team" {
  name               = "${var.module_inputs.cluster_name}-carts-team"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.module_inputs.tags
}

resource "aws_iam_role" "eks_admins" {
  name               = "${var.module_inputs.cluster_name}-admins"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.module_inputs.tags
}

## Read-only access entry

resource "aws_eks_access_entry" "read_only_access" {
  cluster_name  = var.module_inputs.cluster_name
  principal_arn = aws_iam_role.eks_read_only.arn
  type          = "STANDARD"
  tags          = var.module_inputs.tags
}

resource "aws_eks_access_policy_association" "view_policy" {
  cluster_name  = var.module_inputs.cluster_name
  principal_arn = aws_eks_access_entry.read_only_access.principal_arn
  policy_arn    = "arn:${var.module_inputs.partition}:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster" # Valid values are namespace or cluster
  }
}

## Developer access entry

resource "aws_eks_access_entry" "developer_access" {
  cluster_name  = var.module_inputs.cluster_name
  principal_arn = aws_iam_role.eks_developers.arn
  type          = "STANDARD"
  tags          = var.module_inputs.tags
}

resource "aws_eks_access_policy_association" "view_policy_carts" {
  cluster_name  = var.module_inputs.cluster_name
  principal_arn = aws_eks_access_entry.developer_access.principal_arn
  policy_arn    = "arn:${var.module_inputs.partition}:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["carts"]
  }
}

resource "aws_eks_access_policy_association" "edit_policy_assets" {
  cluster_name  = var.module_inputs.cluster_name
  principal_arn = aws_eks_access_entry.developer_access.principal_arn
  policy_arn    = "arn:${var.module_inputs.partition}:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["assets"]
  }
}

## Carts Team access entry

resource "aws_eks_access_entry" "carts_team_access" {
  cluster_name      = var.module_inputs.cluster_name
  principal_arn     = aws_iam_role.eks_carts_team.arn
  kubernetes_groups = ["carts-team"]
  type              = "STANDARD"
  tags              = var.module_inputs.tags
}
