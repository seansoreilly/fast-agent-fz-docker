resource "aws_ecs_cluster" "cluster" {
  name = "${local.name_prefix}-cluster"

  tags = {
    Name        = "${local.name_prefix}-cluster"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7

  tags = {
    Name        = "${local.name_prefix}-log-group"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${local.name_prefix}-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = local.image_uri
      essential = true
      environment = [
        { name = "ANTHROPIC_API_KEY", value = var.anthropic_api_key },
        { name = "OPENAI_API_KEY", value = var.openai_api_key },
        { name = "FAT_ZEBRA_API_URL", value = var.fat_zebra_api_url },
        { name = "FAT_ZEBRA_USERNAME", value = var.fat_zebra_username },
        { name = "FAT_ZEBRA_TOKEN", value = var.fat_zebra_token },
        { name = "PYTHONUNBUFFERED", value = "1" },
        { name = "DEBUG_MCP_SERVER", value = "true" }
      ]
      portMappings = [
        {
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:7860/ || exit 0"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 40
      }
    }
  ])

  tags = {
    Name        = "${local.name_prefix}-task-def"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}

resource "aws_lb" "alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.use_default_vpc ? [aws_subnet.subnet_a[0].id, aws_subnet.subnet_b[0].id] : var.subnet_ids

  tags = {
    Name        = "${local.name_prefix}-alb"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${local.name_prefix}-tg"
  port        = local.container_port
  protocol    = "HTTP"
  vpc_id      = local.use_default_vpc ? aws_vpc.default[0].id : var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200,302,307"
  }

  tags = {
    Name        = "${local.name_prefix}-tg"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:151444831552:certificate/5002f00e-3053-4f57-b4fe-0eaeb3d9c7ac"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_ecs_service" "service" {
  name                              = "${local.name_prefix}-service"
  cluster                           = aws_ecs_cluster.cluster.id
  task_definition                   = aws_ecs_task_definition.task.arn
  desired_count                     = var.initial_desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 120
  enable_execute_command            = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.fargate.id]
    subnets          = local.use_default_vpc ? [aws_subnet.subnet_a[0].id, aws_subnet.subnet_b[0].id] : var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  depends_on = [aws_lb_listener.listener]

  tags = {
    Name        = "${local.name_prefix}-service"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}
