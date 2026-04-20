#!/bin/bash
set -e
aws ecs update-service \
  --cluster assaabloy-app-cluster \
  --service assaabloy-app-service \
  --force-new-deployment \
  --region ${{ secrets.AWS_REGION }}
