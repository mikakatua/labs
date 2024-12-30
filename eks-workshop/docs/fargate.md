# Fargate

[AWS Fargate](https://aws.amazon.com/fargate/) is a technology that provides on-demand, right-sized compute capacity for containers. With AWS Fargate, you don't have to provision or manage EC2 instances to run containers. Amazon EKS integrates Kubernetes controllers that are responsible for scheduling Pods onto Fargate.

You can control which Pods start on Fargate and how they run defining Fargate profiles in your Amazon EKS cluster. You can add up to 5 selectors to each profile. Each selector contains a namespace and optional labels. Pod that matches any of the selectors are scheduled on Fargate. If a Pod matches multiple Fargate profiles, you can specify which profile to use by adding the Pod label: `eks.amazonaws.com/fargate-profile: <fargate-profile>`.

> [!NOTE]
> When using the [EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest), Fargate profiles are defined in the `fargate_profiles` input.

The following command creates a profile:
```bash
aws eks create-fargate-profile \
    --cluster-name ${EKS_CLUSTER_NAME} \
    --pod-execution-role-arn $FARGATE_IAM_PROFILE_ARN \
    --fargate-profile-name checkout-profile \
    --selectors '[{"namespace": "checkout", "labels": {"fargate": "yes"}}]' \
    --subnets "[\"$PRIVATE_SUBNET_1\", \"$PRIVATE_SUBNET_2\", \"$PRIVATE_SUBNET_3\"]"
```

We can confirm what resources were provisioned for our Pod from the `checkout` deployment by inspecting the annotation `CapacityProvisioned`:
```
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].metadata.annotations.CapacityProvisioned'
0.25vCPU 1GB
```

The Fargate compute resources are dynamically provisioned for each Pod (based on the sum of the container resource limits), rounded up to the nearest Fargate configuration. That means that if we scale up the deployment replicas each of the Pods is scheduled on a separate Fargate instance.
