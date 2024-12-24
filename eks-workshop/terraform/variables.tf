variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

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
  default     = "1.31.3-20241213"
}

variable "vpc_cidr" {
  description = "Defines the CIDR block used on Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.42.0.0/16"
}

variable "load_balancer_controller_chart_version" {
  description = "The chart version of aws-load-balancer-controller to use"
  type        = string
  default     = "1.10.1"
}

variable "efs_csi_chart_version" {
  description = "The chart version of aws-efs-csi-driver to use"
  type        = string
  default     = "3.1.2"
}

# variable "cluster_autoscaler_chart_version" {
#   description = "The chart version of cluster-autoscaler to use"
#   type        = string
#   default     = "9.43.2"
# }

variable "karpenter_chart_version" {
  description = "The version of Karpenter to use"
  type        = string
  default     = "1.1.0"
}

variable "metrics_server_chart_version" {
  description = "The chart version of metrics-server to use"
  type        = string
  default     = "3.12.2"
}

variable "keda_chart_version" {
  description = "The chart version of KEDA to use"
  type        = string
  default     = "2.16.0"
}

variable "aws_for_fluent_bit_chart_version" {
  description = "The chart version of AWS for fluent bit to use"
  type        = string
  default     = "0.1.34"
}

variable "cert_manager_chart_version" {
  description = "The chart version of cert-manager to use"
  type        = string
  default     = "v1.16.2"
}

variable "opentelemetry_operator_chart_version" {
  description = "The chart version of OpenTelemetry Operator to use"
  type        = string
  default     = "0.75.1"
}

variable "grafana_chart_version" {
  description = "The chart version of Grafana to use"
  type        = string
  default     = "8.8.2"
}
