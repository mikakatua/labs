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
* `API`: Exclusively rely on EKS access entries. **This is recommended method**.

Switching across these authentication modes is a one-way operation — i.e., you can switch from `CONFIG_MAP` to `API_AND_CONFIG_MAP` or `API`, and from `API_AND_CONFIG_MAP` to `API`, but not the opposite.

> [!NOTE]
> The Terraform EKS module set the authentication mode for the cluster to `API_AND_CONFIG_MAP` by default.

You can check which method your cluster is configured with the command:
```bash
aws eks describe-cluster --name $EKS_CLUSTER_NAME --query 'cluster.accessConfig'
```

If your cluster uses the API as one of the authentication options, you can list the access entries with:
```bash
aws eks list-access-entries --cluster $EKS_CLUSTER_NAME
```

And get more details with `aws eks describe-access-entry`, for example:
```
$ aws eks describe-access-entry --cluster $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::637423329338:role/eks-workshop-ng-default
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::637423329338:role/eks-workshop-ng-default",
        "kubernetesGroups": [
            "system:nodes"
        ],
        "accessEntryArn": "arn:aws:eks:eu-central-1:637423329338:access-entry/eks-workshop/role/637423329338/eks-workshop-ng-default/ccca2378-227c-4bdc-bf4b-6c480c65d025",
        "createdAt": "2025-01-08T18:22:19.055000+01:00",
        "modifiedAt": "2025-01-08T18:22:19.055000+01:00",
        "tags": {},
        "username": "system:node:{{EC2PrivateDNSName}}",
        "type": "EC2_LINUX"
    }
}
```

## Access entries
You can assign an IAM principal (user or role) and one or more access policies to access entries of type `STANDARD`. There other access entry types are used by the Kubernetes nodes (`EC2_LINUX`, `EC2_WINDOWS`, `FARGATE_LINUX`, or `HYBRID_LINUX`)

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
  --role-arn $READ_ONLY_IAM_ROLE --alias readonly --user-alias readonly
```

List the associations of the `eks-workshop-read-only` role:
```bash
aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME \
--principal-arn $READ_ONLY_IAM_ROLE
```

Try the following commands:
```bash
kubectl --context readonly get pod -A # WORKS
kubectl --context readonly delete pod -n assets --all # FAILS
```

Now update the kubeconfig to use another access entry:
```bash
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $DEVELOPERS_IAM_ROLE --alias developer --user-alias developer
```

Try the following commands:
```bash
kubectl --context developer get pod -A # FAILS
kubectl --context developer get pod -n carts # WORKS
kubectl --context developer delete pod -n assets --all # WORKS
```

## Integration with Kubernetes RBAC
The 4 managed EKS access policies are very coarse and do not allow customization. If your use case requires customization or finer granularity, configure access entries with RBAC permissions using Kubernetes groups.

For example, we want to allow the users in the existin IAM role `eks-workshop-carts-team` to view all resources in the `carts` namespace, but also delete pods.

Create a `Role` with the required permissions and map the role to a Kubernetes group named `carts-team`.
```bash
kubectl --context default apply -k manifests/security/rbac
```

This access entry has already been created with Terraform:
```bash
aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $CARTS_TEAM_IAM_ROLE \
  --kubernetes-groups carts-team
```

Set up a new kubeconfig entry that uses the carts teams IAM role to authenticate with the cluster:
```bash
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $CARTS_TEAM_IAM_ROLE --alias carts-team --user-alias carts-team
```

Try the following commands:
```bash
kubectl --context carts-team get pod -n carts # WORKS
kubectl --context carts-team delete pod --all -n carts # WORKS
kubectl --context carts-team delete deployment --all -n carts # FAILS
kubectl --context carts-team get pod -n catalog # FAILS
```

## Migrating from aws-auth identity mapping
You can check the entries in the `aws-auth` ConfigMap with the command:
```bash
kubectl --context default get -o yaml -n kube-system cm aws-auth
```

To migrate entries from this older mechanism create the corresponding access entries with the appropiate permissions and delete the configMap.

