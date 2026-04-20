provider "aws" {
  region = "eu-north-1"
}

resource "aws_ecr_repository" "app_repo" {
  name = "assaabloy-app"
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "assaabloy-app-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "assaabloy-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  # Now using your actual account ID
  execution_role_arn = "arn:aws:iam::879696522469:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "assaabloy-app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-xxxxxx"]   # replace with your subnet IDs
    assign_public_ip = true
  }
}
