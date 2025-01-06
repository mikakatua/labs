# Cluster Access Management
The Cluster Access Management API simplifies identity mapping between AWS IAM and Kubernetes RBAC. It  relies on two basic concepts:
- **Access Entries (Authentication)**: A cluster identity directly linked to an AWS IAM principal (user or role) allowed to authenticate to an Amazon EKS cluster.
- **Access Policies (Authorization)**: Access policies are Amazon EKS-specific policies that assign Kubernetes permissions to access entries. Amazon EKS access policies include Kubernetes permissions, not IAM permissions.

As of today Amazon EKS supports only a few predefined and AWS managed policies and can be listed using the command `aws eks list-access-policies`:

- `AmazonEKSClusterAdminPolicy`, equivalent to the Kubernetes `cluster-admin` role
- `AmazonEKSAdminPolicy`, equivalent to the Kubernetes `admin` role
- `AmazonEKSEditPolicy`, equivalent to the Kubernetes `edit` role
- `AmazonEKSViewPolicy`, equivalent to the Kubernetes `view` role

Be aware that access granted to AWS IAM principals by the Amazon EKS access policies are separate from permissions defined by any AWS IAM policy associated with the AWS IAM principal.

## Authentication mode
Amazon EKS provides three different modes of authentication:
* `CONFIG_MAP`: Uses `aws-auth` ConfigMap exclusively. (this will be deprecated in the future)
* `API_AND_CONFIG_MAP`: Source authenticated IAM principals from both EKS access entries and the `aws-auth` ConfigMap, prioritizing the access entries.
* `API`: Exclusively rely on EKS access entrie. **This is recommended method**.

Switching across these authentication modes is a one-way operation — i.e., you can switch from `CONFIG_MAP` to `API_AND_CONFIG_MAP` or `API`, and from `API_AND_CONFIG_MAP` to `API`, but not the opposite.

> [!NOTE]
> The Terraform EKS module set the authentication mode for the cluster to `API_AND_CONFIG_MAP` by default.

You can check which method your cluster is configured with the command:
```bash
aws eks describe-cluster --name $EKS_CLUSTER_NAME --query 'cluster.accessConfig'
```

## Access entries
You can assign an IAM principal (user or role) and one or more access policies to access entries of type `STANDARD`. There other access entry types are used by the Kubernetes nodes (`EC2_Linux`, `EC2_Windows`, `FARGATE_LINUX`, or `HYBRID_LINUX`)

These commands create an access entry for the IAM role `eks-workshop-read-only` and associate an access policy `AmazonEKSViewPolicy`:
```bash
aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE

aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=cluster
```

This access entry has already been created with the Terraform resources `aws_eks_access_entry` and `aws_eks_access_policy_association`. Aternatively, the [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest#cluster-access-entry) also provides the `access_entries` input to create access entries.

Now update the kubeconfig to use this access entry:
```bash
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $READ_ONLY_IAM_ROLE --alias readonly
```

List the associations of the `eks-workshop-read-only` role:
```bash
aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME \
--principal-arn $READ_ONLY_IAM_ROLE
```

## Integration with Kubernetes RBAC
The 4 managed EKS access policies are very coarse and do not allow customization.If your use case requires customization or finer granularity, you’ll need to join EKS access entry with native Kubernetes RBAC to achieve what you need to do.