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

You can initiate an update of an existing managed node group like so:
```
# Set environment variables from terraform outputs
eval $(terraform -chdir=terraform output -json environment_variables | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')

aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```
By default, the latest available AMI version for the node group's Kubernetes version is used.

## Cluster Upgrades
Refer the [Amazon EKS Upgrades Workshop](https://catalog.us-east-1.prod.workshops.aws/workshops/693bdee4-bc31-41d5-841f-54e3e54f8f4a) for step-by-step guidance and best practices in planning and upgrading EKS Clusters.
