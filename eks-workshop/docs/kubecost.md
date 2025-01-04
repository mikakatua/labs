# Kubecost
[Kubecost](https://www.kubecost.com/) provides real-time cost visibility and insights for teams using Kubernetes, helping you continuously reduce your cloud costs. Kubecost is built on [OpenCost](https://www.opencost.io/), which was recently accepted as a Cloud Native Computing Foundation (CNCF) Sandbox project, and is actively supported by AWS.

Kubecost has been installed using the [Kubecost official Helm chart](https://github.com/kubecost/cost-analyzer-helm-chart) and exposed using a `LoadBalancer` service. We can find the URL to access it like so:
```bash
echo "http://$(kubectl get svc -n kubecost kubecost-cost-analyzer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9090"
```

> [!NOTE]
> Currently Kubecost is using a self hosted Prometheus instance within our Kubernetes cluster. You can update the Kubecost deployment configuration to use Amazon Managed Service for Prometheus (AMP) instead. For more information check out [this following blog post](https://aws.amazon.com/blogs/mt/integrating-kubecost-with-amazon-managed-service-for-prometheus/).



