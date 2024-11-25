# Storage on EKS

Below is a summary of the two AWS storage services we can utilize and integrate with EKS:

- [Amazon Elastic Block Store](https://aws.amazon.com/ebs/) (supports EC2 only): a block storage service that provides direct access from EC2 instances and containers to a dedicated storage volume designed for both throughput and transaction-intensive workloads at any scale.
- [Amazon Elastic File System](https://aws.amazon.com/efs/) (supports Fargate and EC2): provides a fully managed, scalable, and elastic file system so that you can share file data without provisioning or managing storage capacity and performance. EFS stores your data redundantly across multiple Availability Zones (AZ) and offers low latency access from Kubernetes pods irrespective of the AZ in which they are running.
- [Amazon FSx for NetApp ONTAP](https://aws.amazon.com/fsx/netapp-ontap/) (supports EC2 only): Fully managed shared storage built on NetApp’s popular ONTAP file system. FSx for NetApp ONTAP stores your data redundantly across multiple Availability Zones (AZ) and offers low latency access from Kubernetes pods irrespective of the AZ in which they are running.
- [FSx for Lustre](https://aws.amazon.com/fsx/lustre/) (supports EC2 only): a fully managed, high-performance file system optimized for workloads such as machine learning, high-performance computing, video processing, financial modeling, electronic design automation, and analytics. With FSx for Lustre, you can quickly create a high-performance file system linked to your S3 data repository and transparently access S3 objects as files.

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

## Install the EFS CSI driver

In order to utilize Amazon EBS volumes with dynamic provisioning on our EKS cluster, we need to confirm that we have the [Amanzon Elatic Block Store (EBS) CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) installed. The driver allows Amazon EKS clusters to manage the lifecycle of Amazon EBS volumes for persistent volumes.

The EBS CSI driver has been already installed as an [Amazon EKS managed add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html).