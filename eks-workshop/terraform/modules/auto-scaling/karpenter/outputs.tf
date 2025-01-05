output "karpenter_role" {
  description = "The name of the node IAM role"
  value       = module.karpenter_addon.karpenter.node_iam_role_name
}

output "karpenter_sqs_queue" {
  description = "The name of the created Amazon SQS queue"
  value       = module.karpenter_addon.karpenter.sqs.queue_name
}