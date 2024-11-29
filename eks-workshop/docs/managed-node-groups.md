# Managed Node Groups
You deploy one or more worker nodes (EC2 instances) into a node group. The nodes are deployed in an EC2 Auto Scaling group.
[Amazon EKS managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) automate the provisioning and lifecycle management of nodes for Amazon EKS clusters. AWS takes care of tasks like patching, updating, and scaling nodes, easing operational aspects. This greatly simplifies operational activities such as rolling updates for new AMIs or Kubernetes version deployments.

## Upgrading AMIs
The Amazon EKS optimized Amazon Linux AMI is built on top of Amazon Linux 2, and is configured to serve as the base image for Amazon EKS nodes. It's considered a best practice to use the latest version of the EKS-Optimized AMI when you create a node group.

Amazon EKS optimized Amazon Linux AMIs are released periodically in [this repository](https://github.com/awslabs/amazon-eks-ami). They are named by Kubernetes version and the release date of the AMI in the following format:

```
k8s_major_version.k8s_minor_version.k8s_patch_version-release_date
```

To get the latest release for Kubernetes version for your region, you can use the AWS Systems Manager (SSM) Parameter Store command:
```
K8S_VERSION=1.31
aws ssm get-parameter --name /aws/service/eks/optimized-ami/$K8S_VERSION/amazon-linux-2/recommended/release_version --query 'Parameter.Value' --output text
```

When Amazon releases a new AMI version, it does not automatically update the AMI in your managed node groups. Instead, users need to manually initiate updates by modifying the node group's launch template or performing a node group update through the EKS console or API.

> [!NOTE]
> When using the [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) you can set the desired AMI with the `ami_release_version` input and apply the changes to update your cluster nodes.

You can initiate an update of an existing managed node group like so:
```
# Set environment variables from terraform outputs
eval $(terraform -chdir=terraform output -json environment_variables | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')

aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```
By default, the latest available AMI version for the node group's Kubernetes version is used.

## Cluster Upgrades
Refer to the [Best Practices for Cluster Upgrades](https://docs.aws.amazon.com/eks/latest/best-practices/cluster-upgrades.html) documentation.

> [!NOTE]
> When using the [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) you can set the Kubernetes version with the `cluster_version` input and apply the changes to update your cluster nodes.

You can submit the request to upgrade your EKS control plane version using:
```
eksctl upgrade cluster --name $EKS_CLUSTER_NAME --version $K8S_VERSION --approve
```
or
```
aws eks update-cluster-version --name $EKS_CLUSTER_NAME --kubernetes-version $K8S_VERSION
```
After your cluster update is complete, upgrade your Kubernetes add-ons and custom controllers, as required.

Finally, upgrade your nodes to the same Kubernetes minor version as your upgraded cluster.
```
eksctl upgrade nodegroup --name=$EKS_DEFAULT_MNG_NAME --cluster=$EKS_CLUSTER_NAME --kubernetes-version=$K8S_VERSION
```

You cannot downgrade the Kubernetes of an Amazon EKS cluster. Instead, create a new cluster on a previous Amazon EKS version and migrate the workloads.

