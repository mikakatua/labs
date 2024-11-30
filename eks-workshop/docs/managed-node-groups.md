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
```bash
K8S_VERSION=1.31
aws ssm get-parameter --name /aws/service/eks/optimized-ami/$K8S_VERSION/amazon-linux-2/recommended/release_version --query 'Parameter.Value' --output text
```

When Amazon releases a new AMI version, it does not automatically update the AMI in your managed node groups. Instead, users need to manually initiate updates by modifying the node group's launch template or performing a node group update through the EKS console or API.

> [!NOTE]
> When using the [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) you can set the desired AMI with the `ami_release_version` input and apply the changes to update your cluster nodes.

You can initiate an update of an existing managed node group like so:
```bash
# Set environment variables from terraform outputs
eval $(terraform -chdir=terraform output -json environment_variables | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')

aws eks update-nodegroup-version --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME
```
By default, the latest available AMI version for the node group's Kubernetes version is used.

## Cluster Upgrades
Refer to the [Best Practices for Cluster Upgrades](https://docs.aws.amazon.com/eks/latest/best-practices/cluster-upgrades.html) documentation.

> [!NOTE]
> When using the [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) you can set the Kubernetes version with the `cluster_version` input and apply the changes to update your cluster nodes.

You can submit the request to upgrade your EKS control plane version using `eksctl`:
```bash
eksctl upgrade cluster --name $EKS_CLUSTER_NAME --version $K8S_VERSION --approve
```
or AWS CLI:
```bash
aws eks update-cluster-version --name $EKS_CLUSTER_NAME --kubernetes-version $K8S_VERSION
```
After your cluster update is complete, upgrade your Kubernetes add-ons and custom controllers, as required.

Finally, upgrade your nodes to the same Kubernetes minor version as your upgraded cluster.
```bash
eksctl upgrade nodegroup --name=$EKS_DEFAULT_MNG_NAME --cluster=$EKS_CLUSTER_NAME --kubernetes-version=$K8S_VERSION
```

You cannot downgrade the Kubernetes of an Amazon EKS cluster. Instead, create a new cluster on a previous Amazon EKS version and migrate the workloads.

As an alternative to in-place cluster upgrades, you can use blue/green strategy. This requires to run 2 clusters in parallel and give us the possibility to switch back to the old cluster if something goes wrong.
Migration of the workloads should be planned carefully, especially if they depend on each other or for stateful workloads where data has to be backed up and migrated to a new cluster.

## Graviton (ARM) instances
AWS offers 3 processor types for EC2 as well as EC2-backed EKS managed node groups: Intel, AMD, and ARM (AWS Graviton). [AWS Graviton processors](https://aws.amazon.com/ec2/graviton/) are designed by AWS to deliver the best price performance for your cloud workloads running in Amazon EC2.
Graviton-based instances can be identified by the letter g in the Processor family section of the [Instance type naming convention](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#instance-type-names).
AWS Graviton processors are built on the AWS Nitro System. AWS built the [AWS Nitro System](https://aws.amazon.com/ec2/nitro) to deliver practically all of the compute and memory resources of the host hardware to your instances.

> [!NOTE]
> AWS Graviton requires ARM compatible container images, ideally multi-architecture (ARM64 and AMD64) allowing cross-compatibility with both Graviton and x86 instance types.

The configuration of tainted nodes is useful in scenarios where we need to ensure that only specific pods are to be scheduled on certain node groups with special hardware (such as Graviton-based instances or attached GPUs). EKS automatically adds certain node labels to allow for easier filtering, including labels for the OS type, managed node group name, instance type and others.

**Example**: let's configure our application to deploy the UI microservice only on nodes that are part of a Graviton-based managed node group.

Here's an example configuration for the Terraform module:
```
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  ...
  eks_managed_node_groups = {
    graviton = {
      instance_types = ["t4g.medium"]
      desired_capacity = 3
      min_capacity     = 3
      max_capacity     = 6
      ami_type         = "AL2023_ARM_64_STANDARD"

      taints = {
        dedicated = {
          key    = "frontend"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      }
    }
  }
}

```
We added a tag to the nodes in the `graviton` group to ensure that any pods that are already running are evicted if they do not have a matching toleration. Also, no new pods will be scheduled on to this managed node group without an appropriate toleration.

The following Kustomize patch describes the changes needed to our deployment configuration in order to enable this setup:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ui
spec:
  template:
    spec:
      tolerations:
        - key: "frontend"
          operator: "Exists"
          effect: "NoExecute"
      nodeSelector:
        kubernetes.io/arch: arm64
```

## Spot instances
[Amazon EC2 Spot Instances](https://aws.amazon.com/ec2/spot/) use spare EC2 capacity that is available for less than the On-Demand price. Your Spot Instance runs whenever capacity is available.

Because Spot is spare Amazon EC2 capacity, which can change over time, we recommend that you use Spot capacity for workloads that can tolerate periods where the required capacity isn't available.

One of the best practices to successfully adopt Spot Instances is to implement **Cluster Autoscaler with Spot Instance diversification** as part of your configuration. We can diversify Spot Instance pools using two strategies:
* By creating multiple node groups, each of different sizes. For example, a node group of size 4 vCPUs and 16GB RAM, and another node group of 8 vCPUs and 32GB RAM.
* By Implementing instance diversification within the node groups, by selecting a mix of instance types and families from different Spot Instance pools that meet the same vCPUs and memory criteria.

Find more information about using Spot instances [here](./spot-instances.md)

**Tip**: To help us to select the appropriate instance types, we can use [amazon-ec2-instance-selector](https://github.com/aws/amazon-ec2-instance-selector) which recommends instance types based on resource criteria like vcpus and memory. For example:
```bash
ec2-instance-selector --vcpus 2 --memory 4 --gpus 0 --current-generation \
  -a x86_64 --deny-list 't.*' --output table-wide
```
> [!NOTE]
> When using the [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) set the `capacity_type = "SPOT"` in the node group to use spot instances.

aws eks create-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name managed-spot \
  --node-role $SPOT_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --instance-types c5.large c5d.large c5a.large c5ad.large c6a.large \
  --capacity-type SPOT \
  --scaling-config minSize=2,maxSize=3,desiredSize=2 \
  --disk-size 20

We can list all of the nodes in our existing EKS cluster. To get additional detail about the capacity type, we use the `-L eks.amazonaws.com/capacityType` parameter.
```
$ kubectl get nodes -L eks.amazonaws.com/capacityType,eks.amazonaws.com/nodegroup
NAME                                             STATUS   ROLES    AGE     VERSION               CAPACITYTYPE   NODEGROUP
ip-10-42-117-63.eu-central-1.compute.internal    Ready    <none>   39m     v1.31.2-eks-94953ac   ON_DEMAND      default
ip-10-42-126-182.eu-central-1.compute.internal   Ready    <none>   22m     v1.31.2-eks-94953ac   SPOT           managed-spot
ip-10-42-142-31.eu-central-1.compute.internal    Ready    <none>   39m     v1.31.2-eks-94953ac   ON_DEMAND      default
ip-10-42-143-123.eu-central-1.compute.internal   Ready    <none>   2m35s   v1.31.2-eks-94953ac   SPOT           managed-spot
ip-10-42-172-107.eu-central-1.compute.internal   Ready    <none>   39m     v1.31.2-eks-94953ac   ON_DEMAND      default
```
