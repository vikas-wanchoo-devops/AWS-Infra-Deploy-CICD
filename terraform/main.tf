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
# 3. ECS Task Execution Role
#    - Allows ECS tasks to pull images from ECR
#    - Write logs to CloudWatch
# ------------------------------------------------------------
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------
# 4. ECS Task Definition
# ------------------------------------------------------------
resource "aws_ecs_task_definition" "app_task" {
  family                   = "assaabloy-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn

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
# 5. ECS Service
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
