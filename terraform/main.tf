provider "aws" {
  region = "eu-north-1"
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "assaabloy_cluster" {
  name = "assaabloy-app-cluster"
}

# --- Security Group for ALB ---
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "<your-vpc-id>"

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
  name               = "assaabloy-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    "subnet-0d16d36a33d1c1f22",
    "subnet-013e51f5fbc1318cb",
    "subnet-0a4e24f116d3364f9"
  ]
}

# --- Target Group ---
resource "aws_lb_target_group" "assaabloy_tg" {
  name        = "assaabloy-app-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "<your-vpc-id>"

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
  family                   = "assaabloy-app-task"
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
    "image": "879696522469.dkr.ecr.eu-north-1.amazonaws.com/assaabloy-app:latest",
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
        "awslogs-group": "/ecs/assaabloy-app",
        "awslogs-region": "eu-north-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

# --- ECS Service ---
resource "aws_ecs_service" "assaabloy_service" {
  name            = "assaabloy-app-service"
  cluster         = aws_ecs_cluster.assaabloy_cluster.id
  task_definition = aws_ecs_task_definition.assaabloy_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [
      "subnet-0d16d36a33d1c1f22",
      "subnet-013e51f5fbc1318cb",
      "subnet-0a4e24f116d3364f9"
    ]
    assign_public_ip = true
    security_groups  = [aws_security_group.alb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.assaabloy_tg.arn
    container_name   = "app"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.assaabloy_listener]
}
