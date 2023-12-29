################################################################################
## defaults
################################################################################
terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
################################################################################
## security
################################################################################
resource "aws_security_group" "this" {
  name        = "${var.cluster_name}-backstage"
  description = "Backstage security group for traffic between the ALB and the ECS tasks."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.app_port_number
    protocol        = "tcp"
    to_port         = var.app_port_number
    security_groups = var.lb_security_group_ids
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [var.egress_cidr_block]
  }

  tags = merge(var.tags, tomap({
    Name = "${var.cluster_name}-backstage"
  }))
}

################################################################################
## task definition
################################################################################
## container definition
module "backstage_container_definition" {
  source = "./ecs-container-definition"

  name                     = "${var.cluster_name}-backstage"
  image                    = var.container_image
  service                  = "backstage"
  essential                = true
  readonly_root_filesystem = false

  port_mappings = [
    {
      containerPort = var.app_port_number
      hostPort      = var.app_port_number
    }
  ]

  secrets = [
    #    {
    #      name      = "ENABLE_GITHUB_SYNC",
    #      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:ENABLE_GITHUB_SYNC::"
    #    },
    {
      name      = "POSTGRES_USER",
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:POSTGRES_USER::"
    },
    {
      name      = "POSTGRES_PASSWORD",
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:POSTGRES_PASSWORD::"
    },
    {
      name      = "GITHUB_TOKEN",
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:GITHUB_TOKEN::"
    },
    {
      name      = "AUTH_GITHUB_CLIENT_ID",
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:AUTH_GITHUB_CLIENT_ID::"
    },
    {
      name      = "AUTH_GITHUB_CLIENT_SECRET",
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:AUTH_GITHUB_CLIENT_SECRET::"
    },
    {
      name      = "POSTGRES_HOST"
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:POSTGRES_HOST::"
    },
    {
      name      = "POSTGRES_PORT"
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:POSTGRES_PORT::"
    },
    {
      name      = "INTEGRATION_GITHUB_APP_ID"
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:INTEGRATION_GITHUB_APP_ID::"
    },
    {
      name      = "INTEGRATION_GITHUB_WEBHOOK_URL"
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:INTEGRATION_GITHUB_WEBHOOK_URL::"
    },
    {
      name      = "INTEGRATION_GITHUB_CLIENT_ID"
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:INTEGRATION_GITHUB_CLIENT_ID::"
    },
    {
      name      = "INTEGRATION_GITHUB_CLIENT_SECRET"
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:INTEGRATION_GITHUB_CLIENT_SECRET::"
    },
    {
      name      = "INTEGRATION_GITHUB_WEBHOOK_SECRET"
      valueFrom = "${data.aws_secretsmanager_secret.backstage_secret.arn}:INTEGRATION_GITHUB_WEBHOOK_SECRET::"
    },
    {
      name      = "INTEGRATION_GITHUB_PRIVATE_KEY"
      valueFrom = data.aws_secretsmanager_secret.backstage_private_key.arn
    }
  ]

  environment = [
    {
      name  = "BASE_URL"
      value = "https://${var.app_host_name}"
    },
    {
      name  = "FRONTEND_BASE_URL"
      value = "https://${var.app_host_name}"
    },
    {
      name  = "ENVIRONMENT"
      value = var.backstage_environment // TODO: make variable
    }
  ]

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name    = "${var.cluster_name}-backstage"
  cluster = var.cluster_id

  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = var.launch_type
  desired_count   = var.desired_count

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "${var.cluster_name}-backstage"
    target_group_arn = aws_lb_target_group.this.arn
    container_port   = var.app_port_number
  }

  tags = merge(var.tags, tomap({
    Name = "${var.cluster_name}-backstage"
  }))
}

################################################################################
## target group
################################################################################
resource "aws_lb_target_group" "this" {
  # max-length for name is 32 chars
  name        = substr("${var.cluster_name}-backstage", 0, 32)
  port        = var.app_port_number
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    timeout             = "3"
    path                = var.health_check_path_pattern
    unhealthy_threshold = "2"
    matcher             = "200-499"
  }

  tags = merge(var.tags, tomap({
    Name = "${var.cluster_name}-backstage"
  }))
}

## create the forward rule
resource "aws_lb_listener_rule" "forward" {
  listener_arn = var.lb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = [var.app_host_name]
    }
  }

  tags = var.tags
}

# task definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.cluster_name}-backstage"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    module.backstage_container_definition.container_definition
  ])

  tags = merge(var.tags, tomap({
    Name = "${var.cluster_name}-backstage"
  }))
}

################################################################################
## route 53
################################################################################
resource "aws_route53_record" "this" {
  for_each = toset(var.route_53_records)

  zone_id = data.aws_route53_zone.this.id
  name    = each.value
  type    = var.route_53_record_type

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = false
  }
}

################################################################################
## route 53
################################################################################
module "ecs-service-autoscaling" {
  source                    = "git@github.com:cn-terraform/terraform-aws-ecs-service-autoscaling?ref=1.0.6"
  name_prefix               = "${var.cluster_name}-backstage"
  ecs_cluster_name          = var.cluster_name
  ecs_service_name          = aws_ecs_service.this.name
  tags                      = var.tags
  scale_target_min_capacity = var.min_count
  scale_target_max_capacity = var.max_count
}
