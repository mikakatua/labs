output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "ecs_cluster" {
  value = module.ecs.cluster_arn
}

output "lb_listener" {
  value = module.alb.listeners.http.arn
}

output "lb_sg_id" {
  value = module.alb.security_group_id
}

output "lb_dns_name" {
  value = module.alb.dns_name
}

output "db_address" {
  value = module.rds.db_instance_address
}

output "db_port" {
  value = module.rds.db_instance_port
}

output "db_username" {
  value = module.rds.db_instance_username
}

data "aws_secretsmanager_secret" "secrets" {
  arn = module.rds.db_instance_master_user_secret_arn
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

# To see the password run: terraform output -raw db_password
output "db_password" {
  value = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["password"]
  sensitive = true
}
