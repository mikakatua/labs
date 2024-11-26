# EKS Workshop

Original Workshop:
* Documentation: https://www.eksworkshop.com/
* Repo: https://github.com/aws-samples/eks-workshop-v2 (`stable` branch, commit id [077b7ea](https://github.com/aws-samples/eks-workshop-v2/tree/077b7ea90212c9b11711c4cf95bdd7520c65db90))

## Cluster setup

### Provision the infrastructure
```
terraform -chdir=terraform init -upgrade
terraform -chdir=terraform apply -auto-approve
```
#### Abot the EKS addons
To find the supported versions:
```
aws eks describe-addon-versions
```

To find the correct JSON schema for each add-on. Example:
```
aws eks describe-addon-configuration --addon-name aws-ebs-csi-driver \
--addon-version v1.37.0-eksbuild.1  | jq -r '.configurationSchema | fromjson'
```

### Update the kubeconfig file
```
aws eks update-kubeconfig --name eks-workshop
```

### Install Kubernetes addons

* AWS Load Balancer controller: [instructions](./docs/load-balancer.md)
* EBS and EFS CSI drivers: [instructions](./docs/storage.md)

## Deploy the application
You can find the full source code for the sample application on [GitHub](https://github.com/aws-containers/retail-store-sample-app).
```
kubectl apply -k sample-app
kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
```

Additions to the original base application:
* Ingress resource to expose the UI web store application to the outside world creating an ALB
* EBS volume to be consumed by the MySQL database from the catalog microservice utilizing a statefulset
* EFS volume to store the product images for the assets microservice and scale the deployment to 2 replicas

## Clean up
```
kubectl delete -k sample-app
terraform -chdir=terraform destroy -auto-approve
```

