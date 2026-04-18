provider "aws" {
  region = var.region
}

# ECR Repository (fix for missing repo error)
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

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = <<DEFINITION
[
  {
    "name": "app",
    "image": "${aws_ecr_repository.app_repo.repository_url}:latest",
    "essential": true,
    "portMappings": [{ "containerPort": 5000, "hostPort": 5000 }]
  }
]
DEFINITION
}

resource "aws_ecs_service" "app_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
}
