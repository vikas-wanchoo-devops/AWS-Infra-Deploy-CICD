#!/bin/bash

USER=github-actions-user

echo "=== Attached Managed Policies for $USER ==="
aws iam list-attached-user-policies --user-name $USER \
  --query 'AttachedPolicies[*].PolicyName' --output table

echo "=== Inline Policies for $USER ==="
aws iam list-user-policies --user-name $USER \
  --query 'PolicyNames' --output table

echo "=== IAM Roles in Account ==="
aws iam list-roles \
  --query 'Roles[*].RoleName' --output table

# ------------------------------------------------------------
# Extra checks for ECS Task Execution Role
# ------------------------------------------------------------
ROLE=ecsTaskExecutionRole

echo "=== Trusted Entities for $ROLE ==="
aws iam get-role --role-name $ROLE \
  --query 'Role.AssumeRolePolicyDocument.Statement[*].Principal' --output table

echo "=== Policies attached to $ROLE ==="
aws iam list-attached-role-policies --role-name $ROLE \
  --query 'AttachedPolicies[*].PolicyName' --output table
