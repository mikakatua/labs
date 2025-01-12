# Monitoring
AWS provides solutions for monitoring and alarming of EKS environments.
* Native services: CloudWatch Container Insights
* Open source managed services: Amazon Managed Service for Prometheus (AMP), Amazon Managed Grafana and AWS Distro for OpenTelemetry (ADOT)

> [!INFO]
> To dive deeper into AWS Observability features take a look at the [One Observability Workshop](https://catalog.workshops.aws/observability/en-US)

> [!INFO]
> Explore a set of opinionated Infrastructure as Code (IaC) modules to help you set up observability for your AWS environments in our [AWS Observability Accelerator for CDK](https://aws-observability.github.io/cdk-aws-observability-accelerator/) and [AWS Observability Accelerator for Terraform](https://aws-observability.github.io/terraform-aws-observability-accelerator/). These modules work with AWS Native services like Amazon CloudWatch and AWS managed observability services such as Amazon Managed Service for Prometheus, Amazon Managed Grafana and AWS Distro for OpenTelemetry (ADOT).

## Monitoring with AMP and ADOT
We can collect the metrics using [AWS Distro for OpenTelemetry](https://aws-otel.github.io/), store them in Amazon Managed Service for Prometheus and visualize using Amazon Managed Grafana. AWS Distro for OpenTelemetry is a secure, production-ready, AWS-supported distribution of the [OpenTelemetry project](https://opentelemetry.io/).

To gather the metrics from the Amazon EKS Cluster, we'll deploy a `OpenTelemetryCollector` custom resource.

```bash
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

## Monitoring with CloudWatch Container Insights
[Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html) is available for Amazon Elastic Container Service (Amazon ECS), Amazon Elastic Kubernetes Service (Amazon EKS), and Kubernetes platforms on Amazon EC2. Amazon ECS support includes support for Fargate.

Container Insights also provides diagnostic information, such as container restart failures, to help you isolate issues and resolve them quickly. You can also set CloudWatch alarms on metrics that Container Insights collects.

### Cluster Metrics
We'll set up Container Insights to collect metrics from Amazon EKS cluster by using the [AWS Distro for OpenTelemetry](https://aws-otel.github.io/) collector.

The OpenTelemetry collector can run in several different modes depending on the telemetry it is collecting. In this case we'll run it as a DaemonSet so that a pod runs on each node in the EKS cluster. This allows us to collect metrics from the node and container runtime. The configuration includes:
* [AWS Container Insights Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/awscontainerinsightreceiver/README.md) (awscontainerinsightreceiver) is an AWS specific receiver that supports CloudWatch Container Insights.
* [AWS CloudWatch EMF Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/awsemfexporter/README.md) converts OpenTelemetry metrics to [AWS CloudWatch Embedded Metric Format (EMF)](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html) and then sends them directly to CloudWatch Logs using the `PutLogEvents` API.

### Using CloudWatch Logs Insights
Container Insights collects metrics by using performance log events with using [Embedded Metric Format](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html) stored in CloudWatch Logs. CloudWatch generates several metrics automatically from the logs which you can view in the CloudWatch console. You can also do a deeper analysis of the performance data that is collected by using CloudWatch Logs Insights queries.

This query shows a list of nodes, sorted by average node CPU utilization.
```
STATS avg(node_cpu_utilization) as avg_node_cpu_utilization by NodeName
| SORT avg_node_cpu_utilization DESC
```

This query displays a list of your pods, sorted by average number of container restarts.
```
STATS avg(number_of_container_restarts) as avg_number_of_container_restarts by PodName
| SORT avg_number_of_container_restarts DESC
```

### Application Metrics
Let's look at how to ingest application metrics using AWS Distro for OpenTelemetry and visualize the metrics using Amazon CloudWatch.

Now we'll deploy a second collector running as a Deployment with a single replica to scrape metrics from the Pods in our cluster. The configuration includes:
* Rather than the AWS Container Insights Receiver we'll use the [Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md) to scrape all of the pods in the EKS cluster.
* We'll use the AWS CloudWatch EMF Exporter for OpenTelemetry Collector but this time we'll use the namespace `ContainerInsights/Prometheus`.

In CloudWatch Dashboards section we can see the dashboard **Order-Service-Metrics**. The query used to create the panel "Orders by Product" is:
```
SELECT COUNT(watch_orders_total) FROM "ContainerInsights/Prometheus" WHERE productId != '*' GROUP BY productId
```