aws iam create-user --user-name github-actions-user

aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
aws iam attach-user-policy --user-name github-actions-user \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess

# Create access key (MANDATORY)
aws iam create-access-key --user-name github-actions-user
