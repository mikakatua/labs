# Argo CD installation
Before starting, make sure you have the `--enable-ssl-passthrough` flag in the command line arguments for the Nginx Ingress Controller. This is a requirement explained in the [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#kubernetesingress-nginx)

Helm deployment
```
helm repo add argo https://argoproj.github.io/argo-helm
helm install my-argo-cd argo/argo-cd --version 5.16.2 --create-namespace -n argocd -f my-values.yaml
```

Get admin password
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Web UI Login: https://argocd-ui.mydomain.net

CLI Login
```
argocd login argocd.mydomain.net
```

Adding a new cluster
```
argocd cluster add cluster1 --kubeconfig=cluster1.yaml
```
:warning: For Kubernetes 1.24+ clusters you may need to apply a workaround (see https://github.com/argoproj/argo-cd/issues/9422)
