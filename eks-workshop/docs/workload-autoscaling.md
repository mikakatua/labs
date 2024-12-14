# Workload Autoscaling
Scaling Pods either horizontally or vertically. There are three main mechanisms for workload autoscaling:
  * Horizontal Pod Autoscaler (HPA)
  * Cluster Proportional Autoscaler (CPA)
  * Kubernetes Event-Driven Autoscaling (KEDA)

 ## Horizontal Pod Autoscaler (HPA)
 The Horizontal Pod Autoscaler(https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) is implemented with the `HorizontalPodAutoscaler` resource and a controller. The controller periodically adjusts the number of replicas in a deployment or statefulset to the target specified by the user by observing metrics such as average CPU utilization, average memory utilization or any other custom metric.

 The [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) provides container metrics that are required by the HPA. The metrics server is not deployed by default in Amazon EKS clusters, it is installed as an add-on.

In [this example](../sample-app/ui/hpa.yaml) the HPA will scale up the `ui` deployment up to 4 replicas when the average CPU utilization exceeds 300% of the `resources.requests.cpu` (that is 750m = 3 * 250m).

To observe HPA scale out in response to the policy we have configured we need to generate some load on our application. We'll do that by calling the home page of the workload with [hey](https://github.com/rakyll/hey).

The command below will run the load generator with:

* 10 workers running concurrently
* Sending 5 queries per second each
* Running for a maximum of 60 minutes

```bash
kubectl run load-generator \
  --image=williamyeh/hey:latest \
  --restart=Never -- -c 10 -q 5 -z 60m http://ui.ui.svc/home
```

Now that we have requests hitting our application we can watch the HPA resource to follow its progress:
```bash
kubectl get hpa ui -n ui --watch
```

 ## Cluster Proportional Autoscaler (CPA)
The [Cluster Proportional Autoscaler](https://github.com/kubernetes-sigs/cluster-proportional-autoscaler) is a horizontal pod autoscaler that scales replicas based on the number of nodes in a cluster. This functionality is desirable for applications that need to be autoscaled with the size of the cluster.

Unlike other autoscalers CPA does not rely on the Metrics API and does not require the Metrics Server. The inputs for CPA are number of schedulable cores and nodes in the cluster.

 ## Kubernetes Event-Driven Autoscaling (KEDA)
 [KEDA](https://keda.sh/) provides the capability to scale your workload based on events from various sources. KEDA supports 60+ [scalers](https://keda.sh/docs/scalers/) includig several AWS services.

This has been already deployed by Terraform. You can also deploy it manually:
```bash
# Set environment variables from terraform outputs
eval $(terraform -chdir=terraform output -json environment_variables | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')

helm repo add kedacore https://kedacore.github.io/charts
helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
  --set "podIdentity.aws.irsa.enabled=true" \
  --set "podIdentity.aws.irsa.roleArn=${KEDA_ROLE_ARN}" \
  --wait
```

KEDA creates an HPA resource to scale a Deployment or StatefulSet.