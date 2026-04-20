#!/bin/bash
set -e

# ============================================================
# Script: CreateIAMUser_Roles_manual.sh
# Purpose: One-time manual setup for GitHub Actions IAM user
#          + required AWS policies
#          + programmatic access keys
#          + Terraform backend S3 bucket
#          + ECS Task Execution Role
# ============================================================

# ------------------------------------------------------------
# 1. Create IAM User (MANDATORY)
#    - This user will be used by GitHub Actions for CI/CD
# ------------------------------------------------------------
aws iam create-user --user-name github-actions-user

# ------------------------------------------------------------
# 2. Attach required IAM policies to the user
#    - AmazonEC2ContainerRegistryFullAccess : push/pull images to ECR
#    - AmazonECS_FullAccess                 : manage ECS cluster/services
#    - CloudWatchFullAccess                 : allow ECS tasks to send logs
# ------------------------------------------------------------
aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess

# ------------------------------------------------------------
# 3. Create Access Key (MANDATORY)
#    - Generates AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
#    - Store these securely in GitHub Secrets for CI/CD pipeline
# ------------------------------------------------------------
aws iam create-access-key --user-name github-actions-user

# ------------------------------------------------------------
# 4. Create S3 bucket for Terraform state (MANDATORY, one-time)
#    - Bucket name: assaabloy-terraform-state
#    - Region: eu-north-1
#    - Enables versioning for state file history
# ------------------------------------------------------------
aws s3api create-bucket \
  --bucket assaabloy-terraform-state \
  --create-bucket-configuration LocationConstraint=eu-north-1 \
  --region eu-north-1

aws s3api put-bucket-versioning --bucket assaabloy-terraform-state \
  --versioning-configuration Status=Enabled

# ------------------------------------------------------------
# 5. Create ECS Task Execution Role (MANDATORY, one-time)
#    - This role is assumed by ECS tasks at runtime
#    - Allows ECS tasks to:
#        * Pull container images from ECR
#        * Write logs to CloudWatch
# ------------------------------------------------------------
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
