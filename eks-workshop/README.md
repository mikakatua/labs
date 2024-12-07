# EKS Workshop

Original Workshop:
* Documentation: https://www.eksworkshop.com/
* Repo: https://github.com/aws-samples/eks-workshop-v2 (`stable` branch, commit id [077b7ea](https://github.com/aws-samples/eks-workshop-v2/tree/077b7ea90212c9b11711c4cf95bdd7520c65db90))

## Cluster setup

### Provision the infrastructure
```bash
terraform -chdir=terraform init -upgrade
terraform -chdir=terraform apply -auto-approve
```
#### Abot the EKS addons
List of supported addons (updated on 5/12/2024):
```
accuknox_kubearmor
adot
akuity_agent
amazon-cloudwatch-observability
amazon-sagemaker-hyperpod-taskgovernance
aws-ebs-csi-driver
aws-efs-csi-driver
aws-guardduty-agent
aws-mountpoint-s3-csi-driver
aws-network-flow-monitoring-agent
calyptia_fluent-bit
catalogic-software_cloudcasa
cisco_cisco-cloud-observability-collectors
cisco_cisco-cloud-observability-operators
coredns
cribl_cribledge
datadog_operator
datree_engine-pro
dynatrace_dynatrace-operator
eks-pod-identity-agent
factorhouse_kpow
grafana-labs_kubernetes-monitoring
groundcover_agent
guance_datakit
haproxy-technologies_kubernetes-ingress-ee
kong_konnect-ri
kubecost_kubecost
kube-proxy
leaksignal_leakagent
netapp_trident-operator
new-relic_kubernetes-operator
nirmata_kyverno
rad-security_rad-security
rafay-systems_rafay-operator
snapshot-controller
snyk_runtime-sensor
solarwinds_swo-k8s-collector-addon
solo-io_gloo-gateway
solo-io_gloo-mesh-starter-pack
solo-io_istio-distro
spacelift_workerpool-controller
splunk_splunk-otel-collector-chart
stormforge_optimize-live
teleport_teleport
tetrate-io_istio-distro
upbound_universal-crossplane
upwind-security_upwind-operator
vpc-cni
```

To find the supported versions:
```bash
aws eks describe-addon-versions
```

To find the correct JSON schema for each add-on. Example:
```bash
aws eks describe-addon-configuration --addon-name aws-ebs-csi-driver \
--addon-version v1.37.0-eksbuild.1  | jq -r '.configurationSchema | fromjson'
```

### Update the kubeconfig file
```bash
aws eks update-kubeconfig --name eks-workshop
```

### Install Kubernetes addons

* AWS Load Balancer controller: [instructions](./docs/load-balancer.md)
* EBS and EFS CSI drivers: [instructions](./docs/storage.md)

## Deploy the application
You can find the full source code for the sample application on [GitHub](https://github.com/aws-containers/retail-store-sample-app).
```bash
kubectl apply -k sample-app
kubectl get all -l app.kubernetes.io/created-by=eks-workshop -A
```

Additions to the original base application:
* Ingress resource to expose the UI web store application to the outside world creating an ALB
* EBS volume to be consumed by the MySQL database from the `catalog-mysql` microservice utilizing a statefulset
* EFS volume to store the product images for the `assets` microservice and scale the deployment to 2 replicas
* Pod Affinity and Anti-Affinity rules to ensure the `checkout` and `checkout-redis` pods run on the desired nodes
* Modified the `catalog` component to run on Spot instances by adding a nodeSelector
* Updated the `checkout` deployment to increase the resources and schedule its pods on Fargate

## Cluster upgrades
For updating self-managed nodes, see [here](https://docs.aws.amazon.com/eks/latest/userguide/update-workers.html). To update managed nodes see instructions [here](./docs/managed-node-groups.md)

## Autoscaling
See [documentation](./docs/autoscaling.md) about how to automatically scaling both the number of pods and a cluster's compute capacity.

## Clean up
```bash
kubectl delete -k sample-app
terraform -chdir=terraform destroy -auto-approve
```

