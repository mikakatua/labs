data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../infra/terraform.tfstate"
  }
}

data "dns_a_record_set" "lb_ips" {
  host = data.terraform_remote_state.infra.outputs.lb_dns_name
}

locals {
  aws_owner = "637423329338"
  dns_name = "myapp-${data.dns_a_record_set.lb_ips.addrs[0]}.nip.io"
  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id
  private_subnets = data.terraform_remote_state.infra.outputs.private_subnets
  ecs_cluster = data.terraform_remote_state.infra.outputs.ecs_cluster
  lb_listener = data.terraform_remote_state.infra.outputs.lb_listener
  lb_sg_id = data.terraform_remote_state.infra.outputs.lb_sg_id
  common_tags = {
    Project     = "myapp"
    Environment = "test"
  }
}

resource "aws_ecs_task_definition" "myapp" {
  family             = "myapp"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = file("myapp-container-definition.json")
  execution_role_arn = "arn:aws:iam::${local.aws_owner}:role/ecsTaskExecutionRole"
  cpu                      = 512
  memory                   = 1024
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  volume {
    name      = "web-html"
    # efs_volume_configuration {
    #   file_system_id = aws_efs_file_system.data.id
    #   root_directory = "/"
    # }
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "myapp-svc" {
  name            = "myapp"
  cluster         = local.ecs_cluster
  task_definition = aws_ecs_task_definition.myapp.arn
  desired_count   = 1
  launch_type = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    security_groups = [aws_security_group.myapp.id]
    subnets         = local.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.myapp.arn
    container_name   = "demo"
    container_port   = 80
  }
  tags = local.common_tags
}

resource "aws_lb_target_group" "myapp" {
  name = "myapp"
  port = "80"
  protocol = "HTTP"
  vpc_id = local.vpc_id
  target_type = "ip"
  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 60
  }
}

resource "aws_lb_listener_rule" "myapp" {
  action {
    target_group_arn = aws_lb_target_group.myapp.arn
    type = "forward"
  }
  condition {
    host_header {
      values = [ local.dns_name ]
    }
  }

  listener_arn = local.lb_listener
  tags = local.common_tags
}

resource "aws_security_group" "myapp" {
  name = "myapp-sg"
  vpc_id = local.vpc_id
  tags = local.common_tags
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.myapp.id
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = local.lb_sg_id # ALB security group
  # cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.myapp.id
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# resource "aws_efs_file_system" "data" {
#   tags = local.common_tags
# }
#
# resource "aws_efs_mount_target" "myapp" {
#   file_system_id = aws_efs_file_system.data.id
#   subnet_id      = local.private_subnets[0]
#   security_groups = [aws_security_group.data.id]
# }
#
# # Security group for EFS Mount Target to allow access only from ECS Service security group
# resource "aws_security_group" "data" {
#   name = "efs-sg"
#   vpc_id = local.vpc_id
#   tags = local.common_tags
# }
#
# resource "aws_security_group_rule" "allow_nfs_inbound" {
#   type = "ingress"
#   security_group_id = aws_security_group.data.id
#   from_port = 2049
#   to_port = 2049
#   protocol = "tcp"
#   source_security_group_id = aws_security_group.myapp.id # ECS security group
#   # cidr_blocks = ["0.0.0.0/0"]
# }

resource "aws_cloudwatch_log_group" "myapp" {
  name = "/ecs/myapp"
  retention_in_days = 7
  tags = local.common_tags
}
