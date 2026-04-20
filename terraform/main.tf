provider "aws" {
  region = "eu-north-1"
}

# ------------------------------------------------------------
# 1. ECR Repository
# ------------------------------------------------------------
resource "aws_ecr_repository" "app_repo" {
  name = "assaabloy-app"
}

# ------------------------------------------------------------
# 2. ECS Cluster
# ------------------------------------------------------------
resource "aws_ecs_cluster" "app_cluster" {
  name = "assaabloy-app-cluster"
}

# ------------------------------------------------------------
# 3. ECS Task Definition
#    - References pre-created execution role
#    - Reduced CPU/Memory for lightweight Flask API
# ------------------------------------------------------------
resource "aws_ecs_task_definition" "app_task" {
  family                   = "assaabloy-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # Smallest allowed Fargate configuration
  cpu    = "128"
  memory = "256"

  execution_role_arn = "arn:aws:iam::<account-id>:role/ecsTaskExecutionRole"

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

# ------------------------------------------------------------
# 4. ECS Service
# ------------------------------------------------------------
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
