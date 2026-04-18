#!/bin/bash
set -e
aws ecs update-service \
  --cluster assaabloy-cluster \
  --service assaabloy-service \
  --force-new-deployment \
  --region ${{ secrets.AWS_REGION }}
