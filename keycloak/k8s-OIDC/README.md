# Kubernetes authentication with OpenID Connect (Keycloak)
Create a SSL certificate for `oidc.mydomain.net` signed by the Kubernetes CA

Deploy Keycloak
```
kubectl create ns keycloak
helm repo add codecentric https://codecentric.github.io/helm-charts
helm install keycloak codecentric/keycloak -n keycloak -f myvalues.yaml
```

Enable the following options on api-server. For example, in Minikube, editing `/etc/kubernetes/manifests/kube-apiserver.yaml`
```
...
spec:
  containers:
  - command:
    - kube-apiserver
...
    - --oidc-issuer-url=https://oidc.mydomain.net/auth/realms/master
    - --oidc-client-id=kubernetes
    - --oidc-username-claim=name
    - --oidc-groups-claim=groups
    - --oidc-ca-file=/var/lib/minikube/certs/ca.crt
```

Keycloak configuration:
1. Create the group `developers`
2. Create the user `alice`
3. Add the credentials: password `secret`, temporary OFF
4. Add the user `alice` to the group `developers`
5. Add the attributes `name=alice` to the user
6. Create the client ID `kubernetes`
7. For this client, add two mappers:
> - Name: name
> - Mapper Type: User Attribute
> - User Attribute: name
> - Token Claim Name: name
> - Claim JSON Type: String

> - Name: groups
> - Mapper Type: Group Membership
> - Token Claim Name: groups
> - Full group path: OFF


Create a role with the permissions for the `developers` group
```
kubectl apply -f developerRole.yaml
```

Get a JWT for user `alice`
```
JWT=$(curl -k -s -X POST https://oidc.mydomain.net/auth/realms/master/protocol/openid-connect/token -d grant_type=password -d client_id=kubernetes -d username=alice -d password=secret -d scope=openid -d response_type=id_token)
```

Configure *kubectl*
```
kubectl config set-credentials alice  \
--auth-provider=oidc  \
--auth-provider-arg=idp-issuer-url=https://oidc.mydomain.net/auth/realms/master  \
--auth-provider-arg=client-id=kubernetes  \
--auth-provider-arg=refresh-token=$(echo $JWT | jq -r '.refresh_token') \
--auth-provider-arg=id-token=$(echo $JWT | jq -r '.id_token')

kubectl config set-context alice --cluster=minikube --user=alice
```

Testing
```
kubectl --context=alice get pods
kubectl --context=alice auth can-i get secrets
```

