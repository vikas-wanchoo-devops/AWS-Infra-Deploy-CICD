provider "aws" {
  region = var.region
}

# --- ECR Repository ---
resource "aws_ecr_repository" "app_repo" {
  name = var.app_name
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Environment = "dev"
    Project     = "assaabloy-pipeline"
  }
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "assaabloy_cluster" {
  name = "${var.app_name}-cluster"
}

# --- Security Group for ALB ---
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [description, tags]
  }
}

# --- Security Group for ECS Tasks ---
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Allow ALB to reach ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [description, tags]
  }
}

# --- Application Load Balancer ---
resource "aws_lb" "assaabloy_alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnets
}

# --- Target Group ---
resource "aws_lb_target_group" "assaabloy_tg" {
  name        = "${var.app_name}-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# --- HTTP Listener ---
resource "aws_lb_listener" "assaabloy_listener" {
  load_balancer_arn = aws_lb.assaabloy_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.assaabloy_tg.arn
  }
}

# --- HTTPS Listener ---
resource "aws_lb_listener" "assaabloy_https_listener" {
  load_balancer_arn = aws_lb.assaabloy_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.assaabloy_tg.arn
  }
}

# --- Redirect HTTP → HTTPS ---
resource "aws_lb_listener_rule" "http_to_https_redirect" {
  listener_arn = aws_lb_listener.assaabloy_listener.arn
  priority     = 1

  action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "assaabloy_task" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_repo_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    }
  ])
}

# --- ECS Service ---
resource "aws_ecs_service" "assaabloy_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.assaabloy_cluster.id
  task_definition = aws_ecs_task_definition.assaabloy_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_task_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.assaabloy_tg.arn
    container_name   = "app"
    container_port   = 5000
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.assaabloy_listener,
    aws_lb_listener.assaabloy_https_listener
  ]
}
