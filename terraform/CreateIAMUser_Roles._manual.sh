#!/bin/bash
set -e

# ============================================================
# Script: CreateIAMUser_Roles_manual.sh
# Purpose: One-time manual setup for GitHub Actions IAM user
#          + required AWS policies
#          + programmatic access keys
#          + Terraform backend S3 bucket
# ============================================================

# ------------------------------------------------------------
# 1. Create IAM User (MANDATORY)
# ------------------------------------------------------------
aws iam create-user --user-name github-actions-user

# ------------------------------------------------------------
# 2. Attach required IAM policies
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
#    - Store these securely in GitHub Secrets
# ------------------------------------------------------------
aws iam create-access-key --user-name github-actions-user

# ------------------------------------------------------------
# 4. Create S3 bucket for Terraform state (MANDATORY)
#    - Bucket name: assaabloy-terraform-state
#    - Region: eu-north-1
#    - Enables versioning for state file history
# ------------------------------------------------------------
aws s3api create-bucket --bucket assaabloy-terraform-state --region eu-north-1

aws s3api put-bucket-versioning --bucket assaabloy-terraform-state \
  --versioning-configuration Status=Enabled
