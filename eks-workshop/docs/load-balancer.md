# Elastic Load Balancers for a Kubernetes cluster

The [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller) manages ALBs and NLBs to satisfy Kubernetes Ingress and Service resources:
* For each Ingress with `ingressClassName: alb` it creates an ALB listening on ports 80 and 443 by default
* For each Service with `type: LoadBalancer` it creates a NLB

Reusing an existing Load balancer is also possible:
* Using the [IngressGroup](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/annotations/#ingressgroup) feature to group multiple Ingress resources together. The controller will automatically merge Ingress rules for all Ingresses within IngressGroup and support them with a single ALB.
* Using the [TargetGroupBinding](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/targetgroupbinding/targetgroupbinding/) custom resource that can expose your pods using an existing ALB TargetGroup or NLB TargetGroup. This will allow you to provision the load balancer infrastructure completely outside of Kubernetes but still manage the targets with Kubernetes Service.

We can use annotations to configure various behavior of the ALB that is created, such as the health checks it performs on the target pods or the traffic routing mode.

The following diagram explains how application traffic flows differently when the target group mode is `instance` or `ip`.

![Load Balancer](./images/load-balancer.webp)

When the target group mode is `instance`, the traffic flows via a node port created for a service on each node. In this mode, `kube-proxy` routes the traffic to the pod running this service. The service pod could be running in a different node than the node that received the traffic from the load balancer. ServiceA (green) and ServiceB (pink) are configured to operate in "instance mode".

Alternatively, when the target group mode is `ip`, the traffic flows directly to the service pods from the load balancer. In this mode, we bypass a network hop of `kube-proxy`. ServiceC (blue) is configured to operate in "IP mode".

The numbers in the previous diagram represents the following things.

1. The EKS cluster where the services are deployed
2. The ELB instance exposing the service
3. The target group mode configuration that can be either instance or IP
4. The listener protocols configured for the load balancer on which the service is exposed
5. The target group rule configuration used to determine the service destination

There are several reasons why we might want to configure the ELB to operate in IP target mode:

1. It creates a more efficient network path for inbound connections, bypassing `kube-proxy` on the EC2 worker node
2. It removes the need to consider aspects such as `externalTrafficPolicy` and the trade-offs of its various configuration options
3. An application is running on Fargate instead of EC2

## Install the AWS Load Balancer controller
This has been already deployed by Terraform. You can also deploy it manually:
```bash
helm repo add eks-charts https://aws.github.io/eks-charts
helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
  --version "${LBC_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "serviceAccount.name=aws-load-balancer-controller-sa" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
  --wait
```
