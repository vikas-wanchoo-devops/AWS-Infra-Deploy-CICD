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
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

# --- Listener ---
resource "aws_lb_listener" "assaabloy_listener" {
  load_balancer_arn = aws_lb.assaabloy_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.assaabloy_tg.arn
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "assaabloy_task" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::879696522469:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::879696522469:role/ecsTaskRole"

  container_definitions = <<DEFINITION
[
  {
    "name": "app",
    "image": "${aws_ecr_repository.app_repo.repository_url}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/${var.app_name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

# --- ECS Service ---
resource "aws_ecs_service" "assaabloy_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.assaabloy_cluster.id
  task_definition = aws_ecs_task_definition.assaabloy_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.alb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.assaabloy_tg.arn
    container_name   = "app"
    container_port   = 5000
  }

  deployment_controller {
    type = "ECS"
  }

  # ✅ Correct placement for provider >=4.0
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  depends_on = [aws_lb_listener.assaabloy_listener]
}
