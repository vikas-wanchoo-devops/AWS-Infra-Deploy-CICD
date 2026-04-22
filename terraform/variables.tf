variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "assaabloy-app"
}

variable "vpc_id" {
  description = "VPC ID where ECS and ALB will run"
  type        = string
  default     = "vpc-0b5d7248bdde16ef7"
}

variable "subnets" {
  description = "Subnets for ALB and ECS tasks"
  type        = list(string)
  default     = [
    "subnet-0d16d36a33d1c1f22",
    "subnet-013e51f5fbc1318cb",
    "subnet-0a4e24f116d3364f9"
  ]
}

# --- Missing variables added here ---
variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
  default     = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
  default     = "arn:aws:iam::123456789012:role/ecsTaskRole"
}

variable "ecr_repo_url" {
  description = "ECR repository URL for the app image"
  type        = string
  default     = "123456789012.dkr.ecr.eu-north-1.amazonaws.com/assaabloy-app"
}
