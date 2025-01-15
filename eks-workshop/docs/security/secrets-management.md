# Secrets Management

Kubernetes obfuscate sensitive data in a Secret by using a merely base64 encoding, also storing such files in a Git repository is extremely insecure as it is trivial to decode the base64 encoded data. There are a few different approaches you can use for secrets management, for example:
* [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) and [Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
* [Sealed Secrets for Kubernetes](https://github.com/bitnami-labs/sealed-secrets)

## AWS Secrets Manager
AWS Secrets Manager is a service that enables you to easily rotate, manage, and retrieve sensitive data including credentials, API keys, and certificates. The [AWS Secrets and Configuration Provider (ASCP)](https://github.com/aws/secrets-store-csi-driver-provider-aws) for the [Secrets Store CSI Driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver) allows you to make secrets stored in Secrets Manager and parameters stored in Systems Manager Parameter Store appear as files mounted in Kubernetes pods.

ASCP allows workloads running on Amazon EKS to access secrets stored in Secrets Manager through fine-grained access control using IAM roles and policies. When a Pod requests access to a secret, ASCP retrieves the Pod's identity, exchanges it for an IAM role, assumes that role, and then retrieves only the secrets authorized for that role from Secrets Manager.

An alternative approach for integrating AWS Secrets Manager with Kubernetes is through [External Secrets Operator](https://external-secrets.io/). This operator synchronizes secrets from AWS Secrets Manager into Kubernetes Secrets, managing the entire lifecycle through an abstraction layer. It automatically injects values from Secrets Manager into Kubernetes Secrets.


Currently, the catalog Deployment accesses database credentials from the `catalog-db` secret via the environment variables `DB_USER` and `DB_PASSWORD`. We will store the credentials in AWS Secrets Manager. This has already been created with Terraform:

```bash
aws secretsmanager create-secret --name "eks-workshop/catalog-secret" \
  --secret-string '{"username":"catalog_user", "password":"default_password"}'
```

### AWS Secrets and Configuration Provider (ASCP)
To provide access to secrets stored in AWS Secrets Manager via the CSI driver, you'll need a `SecretProviderClass` - a namespaced custom resource that specifies how to create and sync a Kubernetes secret with data from the AWS Secrets Manager secret.

The following command creates a `SecretProviderClass` to sync the secret from AWS Secrets Manager (`eks-workshop/catalog-secret`) into the Kubernetes Secret (`catalog-db`):

```bash
envsubst <<EOF | kubectl create -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: catalog-spc
  namespace: catalog
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "$CATALOG_SECRET_NAME"
        objectType: "secretsmanager"
  secretObjects:
    - secretName: catalog-db
      type: Opaque
      data:
        - objectName: username
          key: username
        - objectName: password
          key: password
EOF
```

Another option is to mount the AWS Secrets Manager secret using the CSI driver at `/mnt/catalog-secret` inside the Pod. This will trigger AWS Secrets Manager to synchronize the stored secret contents with Amazon EKS and create a Kubernetes Secret that can be consumed as environment variables in the Pod. This requires to update the `catalog` deployment as follows:



> ![NOTE]
> The Secrets Store CSI Driver will sync secrets from AWS Secrets Manager into the pod as files (not directly as environment variables).

### External Secrets Operator (ESO)
The goal of External Secrets Operator is to synchronize secrets from external APIs (like AWS Secrets Manager) into Kubernetes. ESO is a collection of CRDs - `ExternalSecret`, `SecretStore` and `ClusterSecretStore` that provide a user-friendly abstraction for the external API that stores and manages the lifecycle of the secrets for you.

## Sealed Secrets
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) provides a mechanism to encrypt a Secret object so that it is safe to store - even to a public Git repository.

> [!NOTE]
> The [Sealed Secrets](https://docs.bitnami.com/tutorials/sealed-secrets) project is not related to AWS Services but a third party open-source tool from [Bitnami Labs](https://bitnami.com/)

Sealed Secrets is composed of two parts:
* A cluster-side controller / operator
* A client-side CLI called `kubeseal`

Install the SealedSecret CRD and server-side controller into the `kube-system` namespace:
```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.3/controller.yaml
```

Once the controller starts up, it looks for a cluster-wide private/public key pair, and generates a new 4096 bit RSA key pair if not found. The private key is persisted in a Secret object in the same namespace as that of the controller (by default kube-system). We can view the contents of the Secret which contains the sealing key as a public/private key pair in YAML format as follows:
```bash
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml
```

When a `SealedSecret` custom resource is deployed to the Kubernetes cluster, the controller will pick it up, unseal it using the private key and create a `Secret` resource. During decryption, the SealedSecret’s namespace/name is used again as the input parameter. This ensures that the `SealedSecret` and `Secret` are strictly tied to the same namespace and name.

The SealedSecrets can have the following three scopes:
* **strict (default)**: The secret must be sealed with exactly the same name and namespace. These attributes become part of the encrypted data and thus changing name and/or namespace would lead to "decryption error".
* **namespace-wide**: The sealed secret can be freely renamed the within a given namespace.
* **cluster-wide**: The secret can be unsealed in any namespace and can be given any name.

The companion CLI tool, `kubeseal`, is used for creating a `SealedSecret` from a `Secret` resource definition using the public key. `kubeseal` can communicate with the controller through the Kubernetes API server and retrieve the public key needed for encrypting a Secret at run-time.

To get the SealedSecret YAML from an existing Secret manifest:
```bash
kubeseal -f sample-app/catalog/secrets.yaml -o yaml
```

The public key may also be downloaded from the controller and saved locally to be used offline.
```bash
kubeseal --fetch-cert > /tmp/public-key-cert.pem
kubeseal --cert=/tmp/public-key-cert.pem -f sample-app/catalog/secrets.yaml -o yaml
```

There could be situations where you are trying to restore the original state of a cluster after a disaster or you want to leverage GitOps workflow to deploy the Kubernetes resources, including SealedSecrets, from a Git repository and create a new EKS cluster. In these cases you must have a backup of the encryption key pair.