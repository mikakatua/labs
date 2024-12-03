# Autoscaling
There are two main mechanisms which can be used to scale automatically:
* **Compute**: by adjusting the number or size of EC2 worker nodes. There are two primary mechanisms available:
  * Kubernetes Cluster Autoscaler tool
  * Karpenter
* **Pods**: by scaling Pods either horizontally or vertically. There are three main mechanisms for workload autoscaling:
  * Horizontal Pod Autoscaler (HPA)
  * Cluster Proportional Autoscaler (CPA)
  * Kubernetes Event-Driven Autoscaling (KEDA)

## Cluster Autoscaler (CA)
The [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler) automatically adjusts the size of a Kubernetes cluster when one of the following conditions is true:
* There are pods that fail to run in a cluster due to insufficient resources.
* There are nodes in a cluster that are underutilized for an extended period of time and their pods can be placed on other existing nodes.
On AWS, Cluster Autoscaler utilizes [Amazon EC2 Auto Scaling Groups](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws) to manage node groups

An IAM role has already been created to provide Cluster Autoscaler the ability to examine and modify EC2 Auto Scaling Groups.

Install cluster-autoscaler as a helm chart:
```bash
# Set environment variables from terraform outputs
eval $(terraform -chdir=terraform output -json environment_variables | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')

helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --version "${CLUSTER_AUTOSCALER_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "autoDiscovery.clusterName=${EKS_CLUSTER_NAME}" \
  --set "awsRegion=${AWS_REGION}" \
  --set "rbac.serviceAccount.name=cluster-autoscaler-sa" \
  --set "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$CLUSTER_AUTOSCALER_ROLE" \
  --wait
```

### Over-Provisioning
This process of adding nodes to a cluster by modifying the ASG requires several minutes before the pods created during application scaling became available. One approach to solve the issue is "over-provisioning" the cluster with extra node(s) that run lower priority pods used as placeholders. These lower priority pods are evicted when critical application pods are deployed.

This is achieved creating `PriorityClass` Kubernetes resources and assign them to Pods. Additionally, a default `PriorityClass` can be assigned to a namespace. For a detailed explanation of how this works, refer to the Kubernetes documentation on [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/Pod-priority-preemption/).

To apply this concept for over-provisioning compute in our EKS cluster, we can follow these steps:

1. Create a priority class with a priority value of **"-1"** and assign it to empty [Pause Container](https://www.ianlewis.org/en/almighty-pause-container) Pods. These empty "pause" containers act as placeholders.

2. Create a default priority class with a priority value of **"0"**. This is assigned globally for the cluster, so any deployment without a specified priority class will be assigned this default priority.

3. When a genuine workload is scheduled, the empty placeholder containers are evicted, allowing the application Pods to be provisioned immediately.

4. Since there are **Pending** (Pause Container) Pods in the cluster, the Cluster Autoscaler will provision additional Kubernetes worker nodes based on the **ASG configuration (`--max-size`)** associated with the EKS node group.

Let's apply these updates to our cluster:
```bash
kubectl apply -k manifests/overprovisioning
kubectl rollout status -n other deployment/pause-pods --timeout 300s
kubectl get nodes -l workshop-default=yes
```
After applying these changes 2 additional nodes have been provisioned by the Cluster Autoscaler

Now scale all your deployments to 5 replicas:
```bash
kubectl get deployments -l app.kubernetes.io/created-by=eks-workshop -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name --no-headers | xargs -n2 sh -c 'kubectl scale deployment -n $0 $1 --replicas=5'
```