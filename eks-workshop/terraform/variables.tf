variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-workshop"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

# Pin the AMI version to manage updates manually and ensure stability
# For development environments, consider setting use_latest_ami_release_version = true
variable "ami_release_version" {
  description = "EKS AMI release version for node groups"
  type        = string
  default     = "1.31.2-20241121"
}

variable "vpc_cidr" {
  description = "Defines the CIDR block used on Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.42.0.0/16"
}

variable "load_balancer_controller_chart_version" {
  description = "The chart version of aws-load-balancer-controller to use"
  type        = string
  default     = "1.10.0"
}

variable "cluster_autoscaler_chart_version" {
  description = "The chart version of cluster-autoscaler to use"
  type        = string
  default     = "9.43.2"
}

variable "karpenter_version" {
  description = "The version of Karpenter to use"
  type        = string
  default     = "1.1.0"
}
