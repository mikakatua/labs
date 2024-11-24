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
* EBS CSI Driver: [instructions](./docs/storage.md)

## Deploy the application
```
kubectl apply -k web-store-application
kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
```

Additions to the original base application:
* Ingress resource to expose the UI web store application to the outside world creating an ALB
* EBS volume to be consumed by the MySQL database from the catalog microservice utilizing a statefulset

## Clean up
```
kubectl delete -k web-store-application
terraform -chdir=terraform destroy -auto-approve
```
