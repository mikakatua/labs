# Observability
AWS provides solutions for monitoring, logging and alarming of EKS environments.
* Native services: CloudWatch Logs
* Open source managed services: Amazon Managed Service for Prometheus (AMP), Amazon Managed Grafana and AWS Distro for OpenTelemetry (ADOT)

## Control Plane Logs
The following logs of the Kubernetes control plane components are available:
* Kubernetes API server component logs (`api`)
* Audit (`audit`)
* Authenticator (`authenticator`)
* Controller manager (`controllerManager`)
* Scheduler (`scheduler`)

The Terraform EKS module enables by default `["audit", "api", "authenticator"]`. See input variable [cluster_enabled_log_types](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest#input_cluster_enabled_log_types)

The log streams are under the CloudWatch log group name `/aws/eks/<my-cluster>/cluster`.

You can use CloudWatch Log Insights to query the EKS control plane logs. For example to identify component that is making a high volume of requests to the Kubernetes API server.

```
fields userAgent, requestURI, @timestamp, @message
| filter @logStream ~= "kube-apiserver-audit"
| stats count(userAgent) as count by userAgent
| sort count desc
```

## Pod Logs utilizing Fluentbit
Kubernetes, by itself, doesn’t provide a native solution to collect and store logs. It configures the container runtime to save logs in JSON format on the node filesystem. Container logs are written to `/var/log/pods/*.log`. Kubelet and container runtime write their own logs to `/var/logs` or to journald, in operating systems with systemd. We can implement pod-level logging by deploying a node-level logging agent as a DaemonSet on each node, such as [Fluent Bit](https://fluentbit.io/).

The [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit) image provides plugins to send logs to CloudWatch Logs, Kinesis Data Firehose, Elasticsearch, S3 and Opensearch.

The AWS for Fluent Bit has already been deployed with Terrraform as an EKS addon. The ConfigMap for aws-for-fluent-bit is configured to stream the container logs from each node to the CloudWatch log group with the prefix `/eks-workshop/worker-fluentbit-logs` and `/eks-workshop/fargate-fluentbit-logs`

## Monitoring EKS Metrics with AMP and ADOT
We can collect the metrics using [AWS Distro for OpenTelemetry](https://aws-otel.github.io/), store them in Amazon Managed Service for Prometheus and visualize using Amazon Managed Grafana. AWS Distro for OpenTelemetry is a secure, production-ready, AWS-supported distribution of the [OpenTelemetry project](https://opentelemetry.io/).

To gather the metrics from the Amazon EKS Cluster, we'll deploy a `OpenTelemetryCollector` custom resource.

```bash
# Set environment variables from terraform outputs
eval $(terraform -chdir=terraform output -json environment_variables | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')

kubectl kustomize manifests/observability/opentelemetry | envsubst | k apply -f -
```
This collector is configured to run as a Deployment with one collector agent

An Amazon Managed Service for Prometheus workspace is already created for you. Let's verify the successful ingestion of the metrics:
```
$ awscurl -X POST --region $AWS_REGION --service aps "${AMP_ENDPOINT}api/v1/query?query=up" | jq '.data.result[1]'
{
  "metric": {
    "__name__": "up",
    "account_id": "6.37423329338e+11",
    "app_kubernetes_io_component": "service",
    "app_kubernetes_io_created_by": "eks-workshop",
    "app_kubernetes_io_instance": "ui",
    "app_kubernetes_io_name": "ui",
    "cluster": "eks-workshop",
    "instance": "10.42.185.178:8080",
    "job": "kubernetes-pods",
    "namespace": "ui",
    "pod": "ui-5dfdb45d77-2q6w6",
    "pod_template_hash": "5dfdb45d77",
    "region": "eu-central-1"
  },
  "value": [
    1735563739,
    "1"
  ]
}
```

An instance of Grafana has been pre-installed in your EKS cluster. To access it, retrieve the URL and credentials:
```bash
kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-user}' | base64 -d; printf "\n"
kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-password}' | base64 -d; printf "\n"
```

### Application metrics
Some of the components in this workshop have been instrumented to provide Prometheus metrics. We can look at an example of these metrics from the orders service like so:
```bash
kubectl -n orders exec deployment/orders -- curl http://localhost:8080/actuator/prometheus
```

The OpenTelemetry collector configuration leverages the [Prometheus Kubernetes service discovery mechanism](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) to automatically discover all pods with a specific annotation `prometheus.io/scrape`, and will enrich metrics it scrapes with Kubernetes metadata such as the namespace and pod name.

Next run a load generator which will place orders through the store and generate application metrics:
```bash
kubectl apply -f manifests/observability/load-generator
```

Open the Grafana dashboard **Order Service Metrics** to review the panels

## Monitoring Metrics with CloudWatch Container Insights

