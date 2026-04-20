#!/bin/bash

USER=github-actions-user

echo "=== Attached Managed Policies ==="
aws iam list-attached-user-policies --user-name $USER --query 'AttachedPolicies[*].PolicyName' --output table

echo "=== Inline Policies ==="
aws iam list-user-policies --user-name $USER --query 'PolicyNames' --output table
