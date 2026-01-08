#!/bin/bash

echo "ECR Login"
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${{ secrets.AWS_ECR_URI }}/cicd-shaymaa:${{ env.VERSION }}

echo "pull image"
docker pull ${{ secrets.AWS_ECR_URI }}/cicd-shaymaa:${{ env.VERSION }}

docker run -dp 3000:3000 --name cicd-shaymaa ${{ secrets.AWS_ECR_URI }}/cicd-shaymaa:${{env.VERSION}}