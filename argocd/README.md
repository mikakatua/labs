# Argo CD installation
Before starting, make sure you have the `--enable-ssl-passthrough` flag in the command line arguments for the Nginx Ingress Controller. This is a requirement explained in the [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#kubernetesingress-nginx)

```
kubectl -n ingress-nginx patch deployment ingress-nginx-controller --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough" }]'
```

## Argo CD Helm deployment
```
helm repo add argo https://argoproj.github.io/argo-helm
helm install my-argo-cd argo/argo-cd --version 5.16.2 --create-namespace -n argocd -f my-values.yaml
```

Get admin password
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Web UI Login: https://argocd-ui.mydomain.net

## Adding a new cluster in Argo CD
CLI Login
```
argocd login argocd.mydomain.net
```

Option 1: Add a cluster using the Kubernetes API server endpoint
```
argocd cluster add cluster1 --kubeconfig=cluster1.yaml
```

Option 2: Add a cluser using the Rancher API endpoint
1. Create a local Rancher user account (e.g. `service-argo`)
2. Create a Rancher API token for that user account, either by logging in and using the GUI (API & Keys -> Add Key) or requesting the token via direct invocation of the `/v3/tokens` API resource.
3. Authorize that user account in the cluster (GUI: Cluster -> Members -> Add) and assign the `cluster-member` role (role should be narrowed down for production usage later).
4. Edit the secret manifest `cluster1-secret.yaml` and provide a configuration reflecting the Rancher setup:
    - `name`: A named reference for the cluster, e.g. "cluster1".
    - `server`: The Rancher auth proxy endpoint for the cluster in the format: `https://<rancher-server-endpoint>/k8s/clusters/<cluster-id>`
    - `config.bearerToken`: The Rancher API token created above
    - `config.tlsClientConfig.caData`: Base64 PEM encoded CA certificate data for Rancher's SSL endpoint. Only needed if the server certificate is not signed by a public trusted CA.
5. Then apply the secret to the Argo CD namespace in the cluster where Argo CD is installed (by default `argocd`):
```
kubectl -n argocd apply -f cluster1-secret.yaml
```
