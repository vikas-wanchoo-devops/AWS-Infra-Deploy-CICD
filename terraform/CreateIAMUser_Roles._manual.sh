#!/bin/bash
set -e

# ============================================================
# Script: CreateIAMUser_Roles_manual.sh
# Purpose: One-time manual setup for GitHub Actions IAM user
#          + required AWS policies
#          + programmatic access keys
#          + Terraform backend S3 bucket
#          + ECS Task Execution Role
#          + ECS Task Role (for ECS Exec)
#          + Security Group rule for ALB → ECS tasks
# ============================================================

# ------------------------------------------------------------
# 1. Create IAM User (MANDATORY)
#    - This user will be used by GitHub Actions for CI/CD
# ------------------------------------------------------------
aws iam create-user --user-name github-actions-user

# ------------------------------------------------------------
# 2. Attach required IAM policies to the user
# ------------------------------------------------------------
aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess

aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess

aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# ------------------------------------------------------------
# 3. Create Access Key (MANDATORY)
# ------------------------------------------------------------
aws iam create-access-key --user-name github-actions-user

# ------------------------------------------------------------
# 4. Create S3 bucket for Terraform state (MANDATORY, one-time)
# ------------------------------------------------------------
aws s3api create-bucket \
  --bucket assaabloy-terraform-state \
  --create-bucket-configuration LocationConstraint=eu-north-1 \
  --region eu-north-1

aws s3api put-bucket-versioning --bucket assaabloy-terraform-state \
  --versioning-configuration Status=Enabled

# ------------------------------------------------------------
# 5. Create ECS Task Execution Role (MANDATORY, one-time)
# ------------------------------------------------------------
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { "Service": "ecs-tasks.amazonaws.com" },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# ------------------------------------------------------------
# 6. Create ECS Task Role (MANDATORY for ECS Exec)
# ------------------------------------------------------------
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { "Service": "ecs-tasks.amazonaws.com" },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

aws iam attach-role-policy \
  --role-name ecsTaskRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# ------------------------------------------------------------
# 7. Security Group Rule (MANDATORY for ALB health checks)
#    - Allows ALB SG to reach ECS task SG on port 5000
#    - Replace <ecs-sg-id> and <alb-sg-id> with actual IDs
# ------------------------------------------------------------
aws ec2 authorize-security-group-ingress \
  --group-id <ecs-sg-id> \              # ECS task SG
  --protocol tcp \
  --port 5000 \
  --source-group <alb-sg-id>            # ALB SG

# ------------------------------------------------------------
# 8. Verification (Optional but Recommended)
# ------------------------------------------------------------
USER=github-actions-user
ROLE_EXEC=ecsTaskExecutionRole
ROLE_TASK=ecsTaskRole

aws iam list-attached-user-policies --user-name $USER \
  --query 'AttachedPolicies[*].PolicyName' --output table

aws iam list-roles \
  --query 'Roles[*].RoleName' --output table

aws iam get-role --role-name $ROLE_EXEC \
  --query 'Role.AssumeRolePolicyDocument.Statement[*].Principal' --output table

aws iam list-attached-role-policies --role-name $ROLE_EXEC \
  --query 'AttachedPolicies[*].PolicyName' --output table

aws iam get-role --role-name $ROLE_TASK \
  --query 'Role.AssumeRolePolicyDocument.Statement[*].Principal' --output table

aws iam list-attached-role-policies --role-name $ROLE_TASK \
  --query 'AttachedPolicies[*].PolicyName' --output table
