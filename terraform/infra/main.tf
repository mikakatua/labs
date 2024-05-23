locals {
  identifier = "test"
  common_tags = {
    Project     = "infrastructure"
    Environment = "test"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${local.identifier}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = local.common_tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.9.0"

  name               = "${local.identifier}-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      # redirect = {
      #   port        = "443"
      #   protocol    = "HTTPS"
      #   status_code = "HTTP_301"
      # }

      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed response content"
        status_code  = "200"
      }
    }
  }

  tags = local.common_tags
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.1"

  cluster_name = "${local.identifier}-ecs"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.common_tags
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.6.0"
  identifier = "${local.identifier}-db"

  engine            = "postgres"
  engine_version    = "16.3"
  family = "postgres16"
  major_engine_version = "16"
  instance_class    = "db.t4g.micro"
  allocated_storage = 5

  create_db_subnet_group = true
  vpc_security_group_ids = [module.database_sg.security_group_id]
  subnet_ids = module.vpc.private_subnets

  # Store master user credentials in AWS Secrets Manager
  manage_master_user_password = true
  username = "postgres"
  port     = 5432

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  # disable backups to create DB faster
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  parameters = [
    {
      name  = "rds.force_ssl"
      value = 0
    }
  ]

  tags = local.common_tags
}

module "database_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.identifier}-db"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within private subnet"
      cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)
    }
  ]

  tags = local.common_tags
}
