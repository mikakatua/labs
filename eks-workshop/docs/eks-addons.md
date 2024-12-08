# EKS addons
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
