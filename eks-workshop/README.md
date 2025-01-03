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

### Update the kubeconfig file
```bash
aws eks update-kubeconfig --name eks-workshop
```

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
* Modified the `catalog` component by adding a node affinity rule to run only on Spot instances
* Updated the `checkout` deployment to increase the resources and schedule its pods on Fargate
* Configure KEDA to scale the `ui` Deployment based on CloudWatch metrics

## Clean up
```bash
# First delete provisioned Load balancers by the ingress ALB controller
kubectl delete ingress -A --all
terraform -chdir=terraform destroy -auto-approve
```

## Documentation
* [About the EKS addons](./docs/eks-addons.md)
* [AWS Load Balancer controller](./docs/load-balancer.md)
* Storage: [EBS and EFS CSI drivers](./docs/storage.md)
* [Cluster upgrades](./docs/managed-node-groups.md)
* Autoscaling: [Scale cluster compute](./docs/cluster-autoscaling.md)
* Autoscaling: [Scale workloads](./docs/workload-autoscaling.md)
* Observability: [Logging](./docs/logging.md)
* Observability: [Monitoring](./docs/monitoring.md)

