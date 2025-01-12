# Access to AWS Services
Applications in a Pod’s containers can make API requests to AWS services using two mechanisms:
* [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) (IRSA)
* [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)

> [!INFO]
> By default Pods use the IAM role linked to the [instance profile](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#ec2-instance-profile) assigned to the node on which its running.

In the following example we want to change the `carts` component of our architecture to use AWS DynamoDB service as its storage backend.

## IAM Roles for Service Accounts
You associate an IAM role with a Kubernetes Service Account and configure your Pods to use that Service Account. The IAM role `eks-workshop-carts-dynamo-irsa` has the required permissions to access DynamoDB. All that's left is to configure the Service Account adding the required annotation to the IAM role, so IRSA can provide the correct authorization for Pods. For example:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::637423329338:role/eks-workshop-carts-dynamo-irsa
  name: carts
  namespace: carts
```

> [!NOTE]
> To use IAM roles for service accounts in your cluster, an [IAM OIDC Identity Provider](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) must be created and associated with a cluster. The Terraform EKS module creates an IAM OIDC provider for the EKS cluster by default.

The IAM role has also been configured with the appropriate trust relationship which allows the OIDC provider associated with your EKS cluster to assume this role as long as the subject is the ServiceAccount for the carts component `system:serviceaccount:carts:carts`. You can view it like so:

```
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name eks-workshop-carts-dynamo-irsa | jq .
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::637423329338:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/5B1F8794C4C52E4101E98664FC964C3C"
      },
      "Action": [
        "sts:TagSession",
        "sts:AssumeRoleWithWebIdentity"
      ],
      "Condition": {
        "StringEquals": {
          "oidc.eks.eu-central-1.amazonaws.com/id/5B1F8794C4C52E4101E98664FC964C3C:sub": "system:serviceaccount:carts:carts"
        }
      }
    }
  ]
}
```

IRSA automatically set these environment variables in the container to allow AWS SDKs to obtain temporary credentials from the AWS STS service:
```
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_REGION=eu-central-1
AWS_ROLE_ARN=arn:aws:iam::637423329338:role/eks-workshop-carts-dynamo-irsa
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=eu-central-1
```
The credentials are requested dynamically when needed using OIDC federation and stored in the `AWS_WEB_IDENTITY_TOKEN_FILE` (contains a JWT token).

## EKS Pod Identities
To use EKS Pod Identity, the **EKS Pod Identity Agent** addon must be installed on your EKS cluster. This has been already installed by Terraform.

The EKS Pod Identity Agent runs as a Kubernetes DaemonSet on all your nodes and only provides credentials to pods on the node that it runs on.

> [!WARNING]
> The EKS Pod Identity Agent is not supported with Fargate

An AWS resource called “Pod Identity Association” is used to connect IAM roles with serviceaccounts. This has been already provisioned by Terraform. To view the association, run the following command.
```
$ aws eks list-pod-identity-associations --cluster-name $EKS_CLUSTER_NAME --namespace carts
{
    "associations": [
        {
            "clusterName": "eks-workshop",
            "namespace": "carts",
            "serviceAccount": "carts",
            "associationArn": "arn:aws:eks:eu-central-1:637423329338:podidentityassociation/eks-workshop/a-aihyvi9tbbw4qzkws",
            "associationId": "a-aihyvi9tbbw4qzkws"
        }
    ]
}
```

The role has also been configured with the appropriate trust relationship, which allows the EKS Service Principal `pods.eks.amazonaws.com` to assume this role for Pod Identity. You can view it with the command below.
```
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name eks-workshop-carts-dynamo-pia | jq .
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": [
        "sts:TagSession",
        "sts:AssumeRole"
      ]
    }
  ]
}
```

Any newly created Pods using that Service Account will be intercepted by the mutating [EKS Pod Identity webhook] which injects credentials into Pods. Take a closer look at the new `carts` Pod to see the new environment variables:
```
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_DEFAULT_REGION=eu-central-1
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_REGION=eu-central-1
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
```
The `AWS_CONTAINER_CREDENTIALS_FULL_URI` is the URL of the EKS Pod Identity Agent, which uses a link-local address on the node. This address is 169.254.170.23 for IPv4 and [fd00:ec2::23] for IPv6 clusters.