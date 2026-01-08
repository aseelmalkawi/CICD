#!/bin/bash

echo "Logging into AWS ECR"
aws ecr get-login-password --region ${{ secrets.AWS_REGION }} \
| docker login --username AWS --password-stdin ${{ secrets.ECR_URI }}

echo "Pulling the Docker image"
docker pull ${{ secrets.ECR_URI }}/cicd-aseel:${{ env.VERSION }}

if docker ps -a --format '{{.Names}}' | grep -wq nodeapp; then
docker stop nodeapp
docker rm nodeapp
fi

echo "Running new container"
docker run -dp 3000:3000 --name nodeapp ${{ secrets.ECR_URI }}/cicd-aseel:${{ env.VERSION }}