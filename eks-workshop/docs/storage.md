## Install the EBS CSI driver

In order to utilize Amazon EBS volumes with dynamic provisioning on our EKS cluster, we need to confirm that we have the [Amanzon Elatic Block Store (EBS) CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) installed. The driver allows Amazon EKS clusters to manage the lifecycle of Amazon EBS volumes for persistent volumes.

The EBS CSI driver has been already installed as an [Amazon EKS managed add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html). Verify the pods are running:
```
$ kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
NAME                                  READY   STATUS    RESTARTS   AGE
ebs-csi-controller-78966bfcb9-2d88d   6/6     Running   0          87m
ebs-csi-controller-78966bfcb9-lpw94   6/6     Running   0          87m
ebs-csi-node-k2nkk                    3/3     Running   0          125m
ebs-csi-node-q8psv                    3/3     Running   0          125m
ebs-csi-node-xhgl2                    3/3     Running   0          125m
```

Starting with EKS 1.30, the EBS CSI Driver use a default StorageClass object configured using Amazon EBS GP3 volume type:
```
$ kubectl get storageclass
NAME                           PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ebs-csi-default-sc (default)   ebs.csi.aws.com         Delete          WaitForFirstConsumer   true                   32m
gp2                            kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  5h40m
```
